"""Runs only when the model packages are installed (./run.sh setup-model)."""
import csv
from pathlib import Path

import pytest

torch = pytest.importorskip("torch")
pytest.importorskip("torch_geometric")
pytest.importorskip("rdkit")

from ddi_service.mvn import Predictor  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
SMILES = {r["drug_id"]: r["smiles"] for r in csv.DictReader(open(ROOT / "tests" / "fixtures" / "drugs.csv"))}


@pytest.fixture(scope="module")
def model():
    return Predictor(str(ROOT / "weights" / "mvn_ddi.pt"))


def test_scores_all_types_at_once(model):
    s = model.scores(SMILES["DB00945"], SMILES["DB00682"])
    assert s.shape == (86,)
    assert ((s >= 0) & (s <= 1)).all()


def test_single_atom_drug_does_not_crash(model):
    # lithium has no bonds; the 2024 code crashed on it
    assert 0 <= model.max_score("[Li+]", SMILES["DB00316"]) <= 1


def test_bad_smiles_is_a_clear_error(model):
    with pytest.raises(ValueError):
        model.scores("not a molecule", SMILES["DB00316"])
