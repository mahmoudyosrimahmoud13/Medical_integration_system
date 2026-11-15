#!/usr/bin/env bash
# HealthHub web app helper. Run ./run.sh help to see the options.
set -e
cd "$(dirname "$0")"

need_modules() {
  if [ ! -d node_modules ]; then
    echo ">> No packages yet, running setup first"
    setup
  fi
}

setup() {
  command -v npm >/dev/null || { echo "!! Node.js 20 or newer is needed: https://nodejs.org"; exit 1; }
  echo ">> Installing packages"
  npm install
  [ -f .env ] || { cp .env.example .env; echo ">> Created .env from .env.example"; }
  echo ">> Setup done"
}

dev()     { need_modules; echo ">> Web app on http://localhost:5173 (talks to the API at ${VITE_PROXY_TARGET:-http://localhost:8020})"; npx vite --host; }
full() {
  need_modules
  if [ -x ../Backend/run.sh ]; then
    echo ">> Starting the API in the background (log in backend.log)"
    ../Backend/run.sh dev > backend.log 2>&1 &
    API_PID=$!
    trap 'echo ">> Stopping the API"; kill $API_PID 2>/dev/null' EXIT
    sleep 5
  else
    echo "!! ../Backend/run.sh not found, starting the web app only"
  fi
  npx vite --host
}
test_()   { need_modules; npx vitest run "$@"; }
watch()   { need_modules; npx vitest; }
check()   { need_modules; npx tsc -b --noEmit; echo ">> Types look good"; }
build()   { need_modules; npm run build; echo ">> Built into dist/"; }
preview() { build; npx vite preview --host --port 4173; }
docker_up()   { echo ">> Starting database + API + web with Docker on http://localhost:8080"; docker compose -f ../docker-compose.yml up --build; }
clean()   { rm -rf node_modules dist *.tsbuildinfo; echo ">> Removed node_modules and dist"; }

case "${1:-help}" in
  setup)   setup ;;
  dev)     dev ;;
  full)    full ;;
  test)    shift; test_ "$@" ;;
  watch)   watch ;;
  check)   check ;;
  build)   build ;;
  preview) preview ;;
  docker)  docker_up ;;
  clean)   clean ;;
  *)
    cat <<'HELP'
Usage: ./run.sh <option>

  setup     install packages and create .env
  dev       start the web app with live reload on http://localhost:5173
  full      start the API (../Backend) and the web app together
  test      run the tests once
  watch     run the tests again on every save
  check     check TypeScript types
  build     build the production files into dist/
  preview   build, then serve dist/ on http://localhost:4173
  docker    run database + API + web in Docker on http://localhost:8080
  clean     delete node_modules and dist
HELP
    ;;
esac
