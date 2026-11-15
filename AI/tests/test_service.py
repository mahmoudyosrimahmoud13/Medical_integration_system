import csv
from pathlib import Path

FIX = Path(__file__).parent / "fixtures"
SMILES = {r["drug_id"]: r["smiles"] for r in csv.DictReader(open(FIX / "drugs.csv"))}


def test_health_reports_data(client):
    body = client.get("/health").json()
    assert body["known_pairs"] == 3
    assert body["model_loaded"] is False


def test_known_interaction_reads_like_a_sentence(client):
    r = client.post("/v1/check", json={"drug_1_id": "DB00682", "drug_2_id": "DB00945", "drug_1_name": "Warfarin", "drug_2_name": "Aspirin"})
    body = r.json()
    assert body["interacts"] is True and body["source"] == "drugbank" and body["type"] == 45
    # order of the sentence follows DrugBank (aspirin acts on warfarin), not the order we asked in
    assert body["description"] == "Aspirin may increase the anticoagulant activities of Warfarin."


def test_types_follow_the_description_file_row_order(client):
    r = client.post("/v1/check", json={"drug_1_id": "DB00641", "drug_2_id": "DB01211", "drug_1_name": "Simvastatin", "drug_2_name": "Clarithromycin"})
    assert r.json()["description"] == "The serum concentration of Simvastatin can be increased when it is combined with Clarithromycin."
    r = client.post("/v1/check", json={"drug_1_id": "DB00203", "drug_2_id": "DB00727"})
    assert "vasodilatory" in r.json()["description"]


def test_unknown_pair_without_model_is_no_interaction(client):
    body = client.post("/v1/check", json={"drug_1_id": "DB00316", "drug_2_id": "DB01060"}).json()
    assert body == {"interacts": False, "source": "none", "description": "No known interaction", "type": None, "confidence": None}


def test_legacy_contract_still_works_with_smiles(client):
    body = client.post("/CheckInteraction", json={"drug_1": SMILES["DB00945"], "drug_2": SMILES["DB00682"]}).json()
    assert body["InteractionResult"] is True
    assert body["InteractionNameIndex"] == 45
    assert body["Source"] == "drugbank"
    none = client.post("/CheckInteraction", json={"drug_1": SMILES["DB00316"], "drug_2": SMILES["DB01060"]}).json()
    assert none["InteractionResult"] is False and none["InteractionNameIndex"] == -1


def test_needs_both_drugs(client):
    assert client.post("/v1/check", json={"drug_1_id": "DB00945"}).status_code == 422
