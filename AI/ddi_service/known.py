"""DrugBank's list of known drug-drug interactions (191,808 pairs, 86 interaction types).

Built by tools/fetch_data.py into data/:
  known_pairs.csv.gz     d1,d2,type      (d1 acts on d2; type is a row index into interaction_types.csv)
  interaction_types.csv  type,template   ("#Drug1 may increase the anticoagulant activities of #Drug2.")
  drugs.csv              drug_id,smiles  (1,706 DrugBank drugs, used to resolve SMILES from old clients)
"""

from __future__ import annotations

import csv
import gzip
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class KnownInteraction:
    first: str   # the drug that causes the effect (#Drug1)
    second: str  # the drug that is affected (#Drug2)
    type: int
    template: str

    def describe(self, names: dict[str, str]) -> str:
        return (self.template.replace("#Drug1", names.get(self.first, self.first))
                .replace("#Drug2", names.get(self.second, self.second)))


class KnownInteractions:
    def __init__(self, data_dir: Path):
        self.pairs: dict[tuple[str, str], int] = {}
        self.templates: dict[int, str] = {}
        self.smiles_to_id: dict[str, str] = {}
        self.id_to_smiles: dict[str, str] = {}
        pairs = data_dir / "known_pairs.csv.gz"
        if not pairs.exists():
            return
        with gzip.open(pairs, "rt", newline="") as f:
            for row in csv.DictReader(f):
                self.pairs[(row["d1"], row["d2"])] = int(row["type"])
        with open(data_dir / "interaction_types.csv", newline="", encoding="utf-8") as f:
            self.templates = {int(r["type"]): r["template"] for r in csv.DictReader(f)}
        drugs = data_dir / "drugs.csv"
        if drugs.exists():
            with open(drugs, newline="", encoding="utf-8") as f:
                for r in csv.DictReader(f):
                    self.id_to_smiles[r["drug_id"]] = r["smiles"]
                    self.smiles_to_id[r["smiles"].strip()] = r["drug_id"]

    @property
    def loaded(self) -> bool:
        return bool(self.pairs)

    def __len__(self) -> int:
        return len(self.pairs)

    def find(self, a: str, b: str) -> KnownInteraction | None:
        for first, second in ((a, b), (b, a)):
            t = self.pairs.get((first, second))
            if t is not None:
                return KnownInteraction(first, second, t, self.templates.get(t, "#Drug1 interacts with #Drug2."))
        return None
