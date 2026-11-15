"""MVN-DDI drug interaction model, ported from the 2024 `machine` branch.

Same layers and weight names as the original, so weights/mvn_ddi.pt loads directly.
Changes from the original:
  * one module instead of layers.py / model.py / data_processing.py / test_functions.py
  * all 86 interaction types are scored in one batched pass (the old code ran 86 passes)
  * drugs with a single atom (e.g. lithium) no longer crash the model
  * the weights load as a plain state_dict, so newer torch / torch_geometric versions work

Needs the optional packages in requirements-model.txt (torch, torch_geometric, rdkit).
"""

from __future__ import annotations

import numpy as np
import torch
import torch.nn.functional as F
from rdkit import Chem, RDLogger
from torch import nn
from torch.nn import ModuleList
from torch_geometric.data import Batch, Data
from torch_geometric.nn import GATConv, LayerNorm, SAGPooling, global_add_pool

RDLogger.DisableLog("rdApp.*")

N_TYPES = 86

# ---------------------------------------------------------------- featurization

_SYMBOLS = ["C", "N", "O", "S", "F", "Si", "P", "Cl", "Br", "Mg", "Na", "Ca", "Fe", "As", "Al", "I", "B", "V", "K", "Tl",
            "Yb", "Sb", "Sn", "Ag", "Pd", "Co", "Se", "Ti", "Zn", "H", "Li", "Ge", "Cu", "Au", "Ni", "Cd", "In",
            "Mn", "Zr", "Cr", "Pt", "Hg", "Pb", "Unknown"]
_HYBRID = [Chem.rdchem.HybridizationType.SP, Chem.rdchem.HybridizationType.SP2, Chem.rdchem.HybridizationType.SP3,
           Chem.rdchem.HybridizationType.SP3D, Chem.rdchem.HybridizationType.SP3D2]


def _one_hot(x, allowed):
    if x not in allowed:
        x = allowed[-1]
    return [x == s for s in allowed]


def atom_features(atom) -> torch.Tensor:
    f = (_one_hot(atom.GetSymbol(), _SYMBOLS)
         + [atom.GetDegree() / 10, atom.GetImplicitValence(), atom.GetFormalCharge(), atom.GetNumRadicalElectrons()]
         + _one_hot(atom.GetHybridization(), _HYBRID)
         + [atom.GetIsAromatic(), atom.GetTotalNumHs()])
    return torch.from_numpy(np.array(f, dtype=np.float32))


class MolGraph:
    """Atoms as nodes (55 features each), bonds as undirected edges."""

    def __init__(self, smiles: str):
        mol = Chem.MolFromSmiles(smiles.strip())
        if mol is None:
            raise ValueError("Unreadable SMILES")
        self.n_atoms = mol.GetNumAtoms()
        self.x = torch.stack([atom_features(a) for a in sorted(mol.GetAtoms(), key=lambda a: a.GetIdx())])
        bonds = [(b.GetBeginAtomIdx(), b.GetEndAtomIdx()) for b in mol.GetBonds()]
        if bonds:
            e = torch.LongTensor(bonds)
            self.edge_index = torch.cat([e, e[:, [1, 0]]], dim=0).T.contiguous()
        else:  # single atom: no bonds
            self.edge_index = torch.zeros((2, 0), dtype=torch.long)


class BipartiteData(Data):
    def __init__(self, edge_index=None, x_s=None, x_t=None):
        super().__init__()
        self.edge_index, self.x_s, self.x_t = edge_index, x_s, x_t

    def __inc__(self, key, value, *args, **kwargs):
        if key == "edge_index":
            return torch.tensor([[self.x_s.size(0)], [self.x_t.size(0)]])
        return super().__inc__(key, value, *args, **kwargs)


def _bipartite(a: MolGraph, b: MolGraph) -> torch.Tensor:
    g = torch.LongTensor(np.array(np.meshgrid(np.arange(a.n_atoms), np.arange(b.n_atoms))))
    return torch.stack([g[0].reshape(-1), g[1].reshape(-1)])

# ---------------------------------------------------------------- layers


class CoAttentionLayer(nn.Module):
    def __init__(self, n_features):
        super().__init__()
        self.w_q = nn.Parameter(torch.zeros(n_features, n_features // 2))
        self.w_k = nn.Parameter(torch.zeros(n_features, n_features // 2))
        self.bias = nn.Parameter(torch.zeros(n_features // 2))
        self.a = nn.Parameter(torch.zeros(n_features // 2))

    def forward(self, receiver, attendant):
        keys = receiver @ self.w_k
        queries = attendant @ self.w_q
        e = queries.unsqueeze(-3) + keys.unsqueeze(-2) + self.bias
        return torch.tanh(e) @ self.a


class RESCAL(nn.Module):
    def __init__(self, n_rels, n_features):
        super().__init__()
        self.n_features = n_features
        self.rel_emb = nn.Embedding(n_rels, n_features * n_features)

    def forward(self, heads, tails, rels, alpha_scores):
        rels = F.normalize(self.rel_emb(rels), dim=-1).view(-1, self.n_features, self.n_features)
        heads, tails = F.normalize(heads, dim=-1), F.normalize(tails, dim=-1)
        scores = heads @ rels @ tails.transpose(-2, -1)
        if alpha_scores is not None:
            scores = alpha_scores * scores
        return scores.sum(dim=(-2, -1))


class IntraGraphAttention(nn.Module):
    def __init__(self, input_dim):
        super().__init__()
        self.intra = GATConv(input_dim, 32, 2)

    def forward(self, data):
        return self.intra(F.elu(data.x), data.edge_index)


class InterGraphAttention(nn.Module):
    def __init__(self, input_dim):
        super().__init__()
        self.inter = GATConv((input_dim, input_dim), 32, 2)

    def forward(self, h_data, t_data, b_graph):
        h_in, t_in = F.elu(h_data.x), F.elu(t_data.x)
        t_rep = self.inter((h_in, t_in), b_graph.edge_index)
        h_rep = self.inter((t_in, h_in), b_graph.edge_index[[1, 0]])
        return h_rep, t_rep


class MVN_DDI_Block(nn.Module):
    def __init__(self, n_heads, in_features, head_out_feats):
        super().__init__()
        self.feature_conv = GATConv(in_features, head_out_feats, n_heads)
        self.intraAtt = IntraGraphAttention(head_out_feats * n_heads)
        self.interAtt = InterGraphAttention(head_out_feats * n_heads)
        self.readout = SAGPooling(n_heads * head_out_feats, min_score=-1)

    def forward(self, h_data, t_data, b_graph):
        h_data.x = self.feature_conv(h_data.x, h_data.edge_index)
        t_data.x = self.feature_conv(t_data.x, t_data.edge_index)
        h_inter, t_inter = self.interAtt(h_data, t_data, b_graph)
        h_data.x = torch.cat([self.intraAtt(h_data), h_inter], 1)
        t_data.x = torch.cat([self.intraAtt(t_data), t_inter], 1)
        h_x, _, _, h_b, _, _ = self.readout(h_data.x, h_data.edge_index, batch=h_data.batch)
        t_x, _, _, t_b, _, _ = self.readout(t_data.x, t_data.edge_index, batch=t_data.batch)
        return h_data, t_data, global_add_pool(h_x, h_b), global_add_pool(t_x, t_b)


class MVN_DDI(nn.Module):
    def __init__(self, in_features, hidd_dim, kge_dim, rel_total, heads_out_feat_params, blocks_params):
        super().__init__()
        self.initial_norm = LayerNorm(in_features)
        self.blocks = []
        self.net_norms = ModuleList()
        for i, (out_feats, n_heads) in enumerate(zip(heads_out_feat_params, blocks_params)):
            block = MVN_DDI_Block(n_heads, in_features, out_feats)
            self.add_module(f"block{i}", block)
            self.blocks.append(block)
            self.net_norms.append(LayerNorm(out_feats * n_heads))
            in_features = out_feats * n_heads
        self.co_attention = CoAttentionLayer(kge_dim)
        self.KGE = RESCAL(rel_total, kge_dim)

    def forward(self, triples):
        h_data, t_data, rels, b_graph = triples
        h_data.x = self.initial_norm(h_data.x, h_data.batch)
        t_data.x = self.initial_norm(t_data.x, t_data.batch)
        repr_h, repr_t = [], []
        for i, block in enumerate(self.blocks):
            h_data, t_data, r_h, r_t = block(h_data, t_data, b_graph)
            repr_h.append(r_h)
            repr_t.append(r_t)
            h_data.x = F.elu(self.net_norms[i](h_data.x, h_data.batch))
            t_data.x = F.elu(self.net_norms[i](t_data.x, t_data.batch))
        heads, tails = torch.stack(repr_h, dim=-2), torch.stack(repr_t, dim=-2)
        return self.KGE(heads, tails, rels, self.co_attention(heads, tails))

# ---------------------------------------------------------------- inference


def _match_keys(saved: dict, expected: dict) -> dict:
    """torch_geometric 2.4 stored a shared GAT weight as lin_src/lin_dst; newer versions call it lin."""
    out = dict(saved)
    for key in expected:
        if key not in out and key.endswith(".lin.weight"):
            src = key[: -len("lin.weight")] + "lin_src.weight"
            if src in out:
                out[key] = out.pop(src)
                out.pop(src.replace("lin_src", "lin_dst"), None)
    for key in list(out):
        if key not in expected and key.endswith((".lin_src.weight", ".lin_dst.weight")):
            lin = key.rsplit(".", 2)[0] + ".lin.weight"
            if lin in expected:
                out.pop(key)
    return out


class Predictor:
    """Loads weights once and scores a drug pair against all 86 interaction types."""

    def __init__(self, weights_path: str):
        torch.set_num_threads(max(1, min(4, torch.get_num_threads())))
        saved = torch.load(weights_path, map_location="cpu", weights_only=True)
        self.model = MVN_DDI(**saved["config"])
        self.model.load_state_dict(_match_keys(saved["state_dict"], self.model.state_dict()))
        self.model.eval()
        self._cache: dict[str, MolGraph] = {}

    def _graph(self, smiles: str) -> MolGraph:
        if smiles not in self._cache:
            if len(self._cache) > 5000:
                self._cache.clear()
            self._cache[smiles] = MolGraph(smiles)
        return self._cache[smiles]

    @torch.no_grad()
    def scores(self, smiles_1: str, smiles_2: str) -> np.ndarray:
        a, b = self._graph(smiles_1), self._graph(smiles_2)
        bip = _bipartite(a, b)
        h = Batch.from_data_list([Data(x=a.x.clone(), edge_index=a.edge_index) for _ in range(N_TYPES)])
        t = Batch.from_data_list([Data(x=b.x.clone(), edge_index=b.edge_index) for _ in range(N_TYPES)])
        g = Batch.from_data_list([BipartiteData(bip, a.x, b.x) for _ in range(N_TYPES)])
        rels = torch.arange(N_TYPES).unsqueeze(0)
        return torch.sigmoid(self.model((h, t, rels, g))).flatten().numpy()

    def max_score(self, smiles_1: str, smiles_2: str) -> float:
        """Highest score over both drug orders: the model is not symmetric."""
        return float(max(self.scores(smiles_1, smiles_2).max(), self.scores(smiles_2, smiles_1).max()))
