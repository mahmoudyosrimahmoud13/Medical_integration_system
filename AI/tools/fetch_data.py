"""Download DrugBank's interaction list (as published with SSI-DDI) and build compact files in data/.

The source files come from https://github.com/kanz76/SSI-DDI (data/ folder). They are derived from
DrugBank, which is free for non-commercial use only. Check DrugBank's license before any commercial use.

Usage: python tools/fetch_data.py [data_dir]
"""

import csv
import gzip
import io
import sys
import urllib.request
from pathlib import Path

BASE = "https://raw.githubusercontent.com/kanz76/SSI-DDI/master/data/"


def get(name: str) -> list[dict]:
    print(f">> Downloading {name}")
    with urllib.request.urlopen(BASE + name, timeout=120) as resp:
        return list(csv.DictReader(io.StringIO(resp.read().decode("utf-8"))))


def main(out: Path) -> None:
    out.mkdir(parents=True, exist_ok=True)
    # Row order of this file is what the type numbers in ddis.csv point to.
    info = get("Interaction_information.csv")
    with open(out / "interaction_types.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["type", "template"])
        for i, row in enumerate(info):
            w.writerow([i, row["Description"]])

    drugs = get("drug_smiles.csv")
    with open(out / "drugs.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["drug_id", "smiles"])
        for row in drugs:
            w.writerow([row["drug_id"], row["smiles"]])

    pairs = get("ddis.csv")
    with gzip.open(out / "known_pairs.csv.gz", "wt", newline="") as f:
        w = csv.writer(f)
        w.writerow(["d1", "d2", "type"])
        for row in pairs:
            w.writerow([row["d1"], row["d2"], row["type"]])
    print(f">> Saved {len(pairs):,} known interactions, {len(info)} types and {len(drugs):,} drugs into {out}")


if __name__ == "__main__":
    main(Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent / "data")
