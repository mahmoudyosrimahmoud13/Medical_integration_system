#!/usr/bin/env bash
# HealthHub backend helper. Run ./run.sh help to see the options.
set -e
cd "$(dirname "$0")"

VENV=".venv"
PY="$VENV/bin/python"

need_venv() {
  if [ ! -x "$PY" ]; then
    echo ">> No virtual environment yet, running setup first"
    setup
  fi
}

setup() {
  echo ">> Creating the Python virtual environment in $VENV"
  python3 -m venv "$VENV"
  "$PY" -m pip install --upgrade pip -q
  echo ">> Installing packages"
  "$PY" -m pip install -r requirements-dev.txt -q
  [ -f .env ] || { cp .env.example .env; echo ">> Created .env from .env.example"; }
  echo ">> Setup done"
}

migrate() { need_venv; echo ">> Updating the database tables"; "$VENV/bin/alembic" upgrade head; }
seed()    { need_venv; echo ">> Loading reference data"; "$PY" -m app.seed "$@"; }

dev() {
  need_venv
  migrate
  seed --demo
  PORT="${PORT:-8020}"
  echo ">> API on http://localhost:$PORT   docs on http://localhost:$PORT/docs"
  "$VENV/bin/uvicorn" app.main:app --reload --host 0.0.0.0 --port "$PORT"
}

start() {
  need_venv
  migrate
  seed
  PORT="${PORT:-8020}"
  "$VENV/bin/uvicorn" app.main:app --host 0.0.0.0 --port "$PORT" --workers "${WORKERS:-2}"
}

test_() { need_venv; "$PY" -m pytest -q "$@"; }
lint()  { need_venv; "$VENV/bin/ruff" check app tests; }
reset() { echo ">> Deleting the local SQLite database"; rm -f healthhub.db; migrate; seed --demo; }
docker_up()   { docker compose up --build -d; echo ">> API on http://localhost:8020/docs"; }
docker_down() { docker compose down; }

case "${1:-help}" in
  setup)  setup ;;
  dev)    dev ;;
  start)  start ;;
  migrate) migrate ;;
  seed)   shift; seed "$@" ;;
  test)   shift; test_ "$@" ;;
  lint)   lint ;;
  reset)  reset ;;
  docker) docker_up ;;
  docker-down) docker_down ;;
  *)
    cat <<'EOF'
Usage: ./run.sh <option>

  setup        create .venv, install packages, create .env
  dev          migrate + demo data + start with auto reload (PORT=8020)
  start        migrate + reference data + start for production (WORKERS=2)
  migrate      create or update the database tables
  seed [--demo] load governorates, areas, specialties, drugs, admin (+ demo users)
  test         run the test suite
  lint         check the code style
  reset        delete the local SQLite database and rebuild it with demo data
  docker       start PostgreSQL + API with Docker Compose
  docker-down  stop the Docker containers
EOF
    ;;
esac
