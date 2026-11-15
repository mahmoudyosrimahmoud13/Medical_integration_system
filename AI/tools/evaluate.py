"""Reproduce the model numbers in PLAN.md.

Scores N known interactions (DrugBank test split) and N random pairs DrugBank does not list,
then prints how often each threshold flags them. Needs requirements-model.txt and the full
DrugBank files from https://github.com/kanz76/SSI-DDI/tree/master/data (ddis.csv, drug_smiles.csv).

Usage: python tools/evaluate.py <ssi-ddi data folder> [N=400]
"""

import csv
import random
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from ddi_service.mvn import Predictor


def main(src: Path, n: int) -> None:
    smiles = {r["drug_id"]: r["smiles"] for r in csv.DictReader(open(src / "drug_smiles.csv"))}
    rows = list(csv.DictReader(open(src / "ddis.csv")))
    known = {(r["d1"], r["d2"]) for r in rows} | {(r["d2"], r["d1"]) for r in rows}
    ids = sorted({r["d1"] for r in rows} | {r["d2"] for r in rows})
    rng = random.Random(7)
    pos = rng.sample([r for r in rows if r["split"] == "testing"], n)
    neg = []
    while len(neg) < n:
        a, b = rng.sample(ids, 2)
        if (a, b) not in known:
            neg.append((a, b))
    model = Predictor(str(Path(__file__).resolve().parent.parent / "weights" / "mvn_ddi.pt"))
    y, best, type_ok = [], [], []
    for r in pos:
        s = model.scores(smiles[r["d1"]], smiles[r["d2"]])
        y.append(1); best.append(s.max()); type_ok.append(s.argmax() == int(r["type"]))
    for a, b in neg:
        y.append(0); best.append(model.scores(smiles[a], smiles[b]).max())
    y, best = np.array(y), np.array(best)
    order = np.argsort(-best)
    ranks = np.empty(len(best)); ranks[order] = np.arange(len(best))
    auc = 1 - (ranks[y == 1].mean() - (y == 1).sum() / 2 + 0.5) / (y == 0).sum()
    print(f"Pairs: {n} known interactions, {n} pairs not listed. AUROC {auc:.3f}")
    print(f"Model's best type equals DrugBank's type: {np.mean(type_ok):.0%}")
    for th in (0.5, 0.7, 0.8, 0.9, 0.95):
        print(f"threshold {th:.2f}: flags {np.mean(best[y == 1] > th):.0%} of real interactions, {np.mean(best[y == 0] > th):.0%} of safe pairs")


if __name__ == "__main__":
    main(Path(sys.argv[1]), int(sys.argv[2]) if len(sys.argv) > 2 else 400)
