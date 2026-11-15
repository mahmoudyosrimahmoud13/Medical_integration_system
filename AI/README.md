# HealthHub AI: drug interaction checks

A small service that tells a doctor whether two drugs interact, in a plain sentence:

> Aspirin may increase the anticoagulant activities of Warfarin.

1. It looks the pair up in **DrugBank's list of known interactions** (191,511 pairs). This is the main answer.
2. For pairs that aren't on the list, it can also ask the **MVN-DDI model** from the 2024 project. This is optional and off by default. It only answers "possible interaction" when it is very sure.

Why it works this way, and the plan for the model and the bone fracture idea: see [PLAN.md](PLAN.md).

## Run it

On Windows use `run.bat` instead of `./run.sh`.

```bash
./run.sh setup     # create .venv and install (small, no PyTorch)
./run.sh dev       # downloads DrugBank's list the first time, then starts on http://localhost:8001/docs
```

To let the backend use it, set this in `Backend/.env`:

```
ML_SERVICE_URL=http://localhost:8001
```

Turn on the model as well (a big download, about 3 GB with PyTorch):

```bash
./run.sh setup-model   # installs PyTorch (CPU) and sets USE_MODEL=true in .env
./run.sh dev
```

| Option        | What it does |
|---------------|--------------|
| `setup`       | create `.venv` and install the small service |
| `setup-model` | also install PyTorch and turn the model on |
| `data`        | download DrugBank's list into `data/` |
| `dev`         | start with auto reload on port 8001 |
| `start`       | start for production |
| `test`        | run the tests (model tests run only after `setup-model`) |
| `lint`        | check the code style |
| `evaluate`    | measure the model on real DrugBank pairs |
| `docker`      | build and run the image (`WITH_MODEL=1 ./run.sh docker` to include the model) |

## API

`POST /v1/check`

```json
{"drug_1_id": "DB00682", "drug_2_id": "DB00945", "drug_1_name": "Warfarin", "drug_2_name": "Aspirin"}
```

```json
{"interacts": true, "source": "drugbank", "type": 45, "confidence": null,
 "description": "Aspirin may increase the anticoagulant activities of Warfarin."}
```

- `source` is `drugbank` (known), `model` (an estimate, only with `USE_MODEL=true`) or `none`.
- You can send SMILES (`drug_1_smiles`) instead of DrugBank ids.

`POST /CheckInteraction` is the 2024 Flask contract (`{"drug_1": smiles, "drug_2": smiles}`), kept for old clients.

`GET /health` shows how many pairs are loaded and whether the model is on.

## Files

```
ddi_service/
  main.py     the API
  known.py    DrugBank lookup
  mvn.py      the MVN-DDI model, ported from the 2024 machine branch
  config.py   settings (USE_MODEL, MODEL_THRESHOLD, DATA_DIR)
weights/mvn_ddi.pt   the 2024 model's weights, converted from ddi.pkl
tools/
  fetch_data.py      downloads DrugBank's list (not stored in git)
  evaluate.py        reproduces the numbers in PLAN.md
```

**Data license:** DrugBank's data is free for non-commercial use only. Check DrugBank's terms before any commercial use.
