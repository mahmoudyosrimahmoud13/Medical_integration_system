#!/usr/bin/env bash
# HealthHub AI (drug interactions) helper. Run ./run.sh help to see the options.
set -e
cd "$(dirname "$0")"
VENV=".venv"; PY="$VENV/bin/python"; PORT="${PORT:-8001}"

need_venv() { [ -x "$PY" ] || setup; }
need_data() { [ -f data/known_pairs.csv.gz ] || data; }

setup() {
  echo ">> Creating the Python virtual environment in $VENV"
  python3 -m venv "$VENV"
  "$PY" -m pip install -q --upgrade pip
  "$PY" -m pip install -q -r requirements-dev.txt
  [ -f .env ] || cp .env.example .env
  echo ">> Setup done"
}
setup_model() {
  need_venv
  echo ">> Installing PyTorch (CPU) and the model packages, this is a big download"
  "$PY" -m pip install torch --index-url https://download.pytorch.org/whl/cpu
  "$PY" -m pip install -r requirements-model.txt
  sed -i.bak 's/^USE_MODEL=.*/USE_MODEL=true/' .env && rm -f .env.bak
  echo ">> Model ready. USE_MODEL=true is set in .env"
}
data()  { need_venv; "$PY" tools/fetch_data.py data; }
dev()   { need_venv; need_data; echo ">> AI service on http://localhost:$PORT/docs"; "$VENV/bin/uvicorn" ddi_service.main:app --reload --host 0.0.0.0 --port "$PORT"; }
start() { need_venv; need_data; "$VENV/bin/uvicorn" ddi_service.main:app --host 0.0.0.0 --port "$PORT"; }
test_() { need_venv; "$PY" -m pytest -q "$@"; }
lint()  { need_venv; "$VENV/bin/ruff" check ddi_service tests tools; }
evaluate() { need_venv; [ -n "$1" ] || { echo "Usage: ./run.sh evaluate <folder with ddis.csv and drug_smiles.csv> [pairs]"; exit 1; }; "$PY" tools/evaluate.py "$@"; }
docker_up() { docker build ${WITH_MODEL:+--build-arg WITH_MODEL=1} -t healthhub-ai . && docker run --rm -p "$PORT:8001" healthhub-ai; }

case "${1:-help}" in
  setup) setup ;;
  setup-model) setup_model ;;
  data) data ;;
  dev) dev ;;
  start) start ;;
  test) shift; test_ "$@" ;;
  lint) lint ;;
  evaluate) shift; evaluate "$@" ;;
  docker) docker_up ;;
  *) cat <<'HELP'
Usage: ./run.sh <option>

  setup        create .venv and install the small service (DrugBank lookup only)
  setup-model  also install PyTorch and turn on the MVN-DDI model (big download)
  data         download DrugBank's interaction list into data/
  dev          start with auto reload on http://localhost:8001 (PORT to change)
  start        start for production
  test         run the tests (model tests run only after setup-model)
  lint         check the code style
  evaluate     measure the model on real DrugBank pairs (see PLAN.md)
  docker       build and run the Docker image (WITH_MODEL=1 to include the model)
HELP
  ;;
esac
