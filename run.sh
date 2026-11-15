#!/usr/bin/env bash
# HealthHub: one script to set up, run and look after everything. Run ./run.sh help for the full list.
set -e
cd "$(dirname "$0")"
ROOT="$(pwd)"
CONF="$ROOT/.run.conf"          # settings remembered between runs (tunnel token, site address). Never in git.
PIDS="$ROOT/logs/healthhub.pids"
WEB_PORT="${WEB_PORT:-8080}"; API_PORT="${API_PORT:-8020}"; AI_PORT=8001

say()  { printf "\n\033[1;33m◆\033[0m \033[1m%s\033[0m\n" "$1"; }
ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn() { printf "  \033[33m!\033[0m %s\n" "$1"; }
fail() { printf "\n\033[31m✗ %s\033[0m\n" "$1"; exit 1; }

show_help() { cat <<EOF

  HealthHub control script

  START
    ./run.sh                     set up whatever is missing, then start HealthHub (Ctrl+C stops it)
                                 it asks what to do with the data: continue, start over with demo data,
                                 or start over empty (Enter = continue)
    ./run.sh --background        same, but keeps running after you close the window (stop with ./run.sh stop)
    ./run.sh --dev               the website reloads as you edit code
    ./run.sh --rebuild           rebuild the website first
    ./run.sh --no-ai             don't start the drug interaction service
    ./run.sh --local-only        only this computer can open it (by default phones on your Wi-Fi can too)

  PUT IT ON THE INTERNET WITHOUT A SERVER (Cloudflare Tunnel)
    ./run.sh --tunnel            free temporary https address (*.trycloudflare.com), no account needed.
                                 The address changes every start. Paste it into the Android app's
                                 "Server address" on the login screen.
    ./run.sh --tunnel-token <token>   your own fixed address (needs a free Cloudflare account and a domain).
                                 Saved, so next time ./run.sh --tunnel is enough. See README "Cloudflare Tunnel".
    ./run.sh tunnel off          forget the saved tunnel token

  DATA
    ./run.sh --keep              continue with the data you have, without asking
    ./run.sh --reset-demo        delete ALL data, then load the demo hospital, doctors, pharmacies and patients
    ./run.sh --reset-empty       delete ALL data, then start empty (only the admin account)
                                 a backup is saved first; add --yes to skip the "type wipe" question
    ./run.sh demo                add the demo data to what you have now (nothing is deleted)
    ./run.sh accounts            list every demo login with its password (doctors, hospitals, pharmacies, patients)
    ./run.sh backup [name]       save the database and uploaded files to one file now
    ./run.sh backups             list the saved backups
    ./run.sh restore <name|latest>   replace everything with a backup (asks first)
    ./run.sh reset [--demo]      delete ALL data without starting (backup first, asks first)

  ANDROID APP ON YOUR PHONE (needs Flutter installed; the phone uses this computer over Wi-Fi)
    ./run.sh app                 run the app on a phone plugged in by USB (or an emulator)
    ./run.sh app apk             build an APK file you can copy to any phone on your Wi-Fi
                                 both point the app at the tunnel address when one is open, otherwise at
                                 http://<this PC's Wi-Fi address>:$WEB_PORT

  WHILE IT RUNS
    ./run.sh status              is it running, the public address, what is in the database
    ./run.sh stop                stop everything (works from any window)
    ./run.sh restart [options]   stop, then start again in the background
    ./run.sh logs [api|ai|web|tunnel]   watch the logs live (Ctrl+C stops watching, HealthHub keeps running)

  CODE
    ./run.sh update              download the newest code from GitHub, then restart
    ./run.sh test                run every test suite (backend, AI, web)

EOF
}

# ---------------------------------------------------------------- saved settings
conf_get() { [ -f "$CONF" ] && grep -E "^$1=" "$CONF" | tail -n 1 | cut -d= -f2- || true; }
conf_set() {
  touch "$CONF"; chmod 600 "$CONF"
  grep -vE "^$1=" "$CONF" >"$CONF.tmp" || true
  [ -n "$2" ] && echo "$1=$2" >>"$CONF.tmp"
  mv "$CONF.tmp" "$CONF"
}

# ---------------------------------------------------------------- helpers
BPY="$ROOT/Backend/.venv/bin/python"
APY="$ROOT/AI/.venv/bin/python"
DB_FILE="$ROOT/Backend/healthhub.db"
port_up() { (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null; }
running() { port_up $API_PORT || port_up $WEB_PORT; }
killtree() { local c; for c in $(pgrep -P "$1" 2>/dev/null); do killtree "$c"; done; kill "$1" 2>/dev/null || true; }

sqlite_only() {
  if [ -n "${DATABASE_URL:-}" ] && [[ "$DATABASE_URL" != sqlite* ]]; then
    fail "This command works with the built-in SQLite database. You set DATABASE_URL to another database; use its own backup tools."
  fi
}

db_count() {  # db_count "<sql>"  -> number, or empty when there is no database yet
  [ -f "$DB_FILE" ] || return 0
  python3 - "$DB_FILE" "$1" <<'PY' 2>/dev/null || true
import sqlite3, sys
try:
    print(sqlite3.connect(sys.argv[1]).execute(sys.argv[2]).fetchone()[0])
except Exception:
    pass
PY
}

has_demo() { [ "$(db_count "select count(*) from users where email='doctor@healthhub.local'")" = "1" ]; }
user_count() { db_count "select count(*) from users"; }

stats() {
  if [ ! -f "$DB_FILE" ]; then warn "No database yet. It is made on the first ./run.sh"; return; fi
  echo "  Accounts       $(db_count "select count(*) from users")"
  echo "  Doctors        $(db_count "select count(*) from doctors where accepted=1")"
  echo "  Hospitals      $(db_count "select count(*) from hospitals where accepted=1")"
  echo "  Pharmacies     $(db_count "select count(*) from pharmacies where accepted=1")"
  echo "  Appointments   $(db_count "select count(*) from appointments")"
  echo "  Messages       $(db_count "select count(*) from chat_messages")"
  has_demo && echo "  Demo data      yes" || echo "  Demo data      no"
}

confirm_wipe() {
  [ "$YES" = 1 ] && return 0
  printf "\n  \033[1;31mThis deletes ALL data:\033[0m every account, appointment, record and message.\n"
  printf "  A backup is saved first, so it can be undone with ./run.sh restore latest.\n"
  printf "  Type \033[1mwipe\033[0m and press Enter to continue: "
  read -r ans || ans=""
  [ "$ans" = "wipe" ] || fail "Nothing was deleted."
}

# Every demo login with its password, grouped by role. Real accounts are listed without a password.
accounts() {
  [ -f "$DB_FILE" ] || { warn "No database yet. Start HealthHub once: ./run.sh"; return 0; }
  python3 - "$DB_FILE" <<'PY'
import sqlite3, sys
db = sqlite3.connect(sys.argv[1])
def rows(sql):
    return db.execute(sql).fetchall()
groups = [
    ("Admin", "ADMIN", "Admin@12345", "select u.email, u.name, '' from users u join user_roles r on r.user_id=u.id where r.role='ADMIN'"),
    ("Doctors", "DOCTOR", "Doctor@12345",
     "select u.email, u.name, s.name || ', ' || a.key from users u join doctors d on d.user_id=u.id "
     "left join specialties s on s.id=d.specialty_id left join areas a on a.id=d.area_id where d.accepted=1 order by u.email!='doctor@healthhub.local', u.name"),
    ("Hospitals", "HOSPITAL", "Hospital@12345",
     "select u.email, h.name, a.key from users u join hospitals h on h.owner_id=u.id left join areas a on a.id=h.area_id order by u.email!='hospital@healthhub.local', h.name"),
    ("Pharmacies", "PHARMACY", "Pharmacy@12345",
     "select u.email, p.name, a.key from users u join pharmacies p on p.owner_id=u.id left join areas a on a.id=p.area_id order by u.email!='pharmacy@healthhub.local', p.name"),
    ("Patients", "PATIENT", "Patient@12345",
     "select u.email, u.name, a.key from users u left join areas a on a.id=u.area_id where u.id in (select user_id from user_roles group by user_id having count(*)=1 and max(role)='PATIENT') "
     "order by u.email!='patient@healthhub.local', u.name"),
]
for title, _, pw, sql in groups:
    data = rows(sql)
    if not data:
        continue
    print(f"\n  {title} ({len(data)})")
    for email, name, where in data:
        demo = email.endswith("@healthhub.local")
        print(f"    {email:<38} {pw if demo else '(own password)':<16} {name}{' (' + where + ')' if where else ''}")
print("\n  Every demo password is the role + @12345. Log in on the website or in the Android app.")
PY
}

# ---------------------------------------------------------------- backups
backup() {  # backup [name]
  sqlite_only
  [ -f "$DB_FILE" ] || { warn "There is no data to back up yet."; return 0; }
  mkdir -p "$ROOT/backups"
  local stamp name file
  stamp="$(date '+%Y-%m-%d_%H%M%S')"
  name="$(echo "${*:-}" | tr -cs 'A-Za-z0-9_-' '-' | sed 's/^-*//;s/-*$//')"
  file="$ROOT/backups/healthhub_${stamp}${name:+_$name}.tar.gz"
  # sqlite3's own backup copy is safe even while the API is writing
  python3 - "$DB_FILE" "$ROOT/backups/.db.tmp" <<'PY'
import sqlite3, sys
src, dst = sqlite3.connect(sys.argv[1]), sqlite3.connect(sys.argv[2])
src.backup(dst); dst.close(); src.close()
PY
  mkdir -p "$ROOT/Backend/media"
  tar -czf "$file" -C "$ROOT/backups" --transform 's|^.db.tmp$|healthhub.db|' .db.tmp -C "$ROOT/Backend" media
  rm -f "$ROOT/backups/.db.tmp"
  ok "Backup saved: backups/$(basename "$file")"
  # keep the 15 newest unnamed backups; named ones stay until you delete them
  ls -1t "$ROOT"/backups/healthhub_*.tar.gz 2>/dev/null | grep -E '_[0-9]{6}\.tar\.gz$' | tail -n +16 | xargs -r rm -f
}

list_backups() {
  ls -1t "$ROOT"/backups/healthhub_*.tar.gz 2>/dev/null | while read -r f; do
    printf "  %-60s %s\n" "$(basename "$f")" "$(du -h "$f" | cut -f1)"
  done
}

restore() {
  sqlite_only
  local target="$*"
  [ -n "$target" ] || fail "Say which backup. Example: ./run.sh restore latest   (see the list with ./run.sh backups)"
  if [ "$target" = "latest" ]; then
    target="$(ls -1t "$ROOT"/backups/healthhub_*.tar.gz 2>/dev/null | head -n 1)"
    [ -n "$target" ] || fail "There are no backups yet."
  elif [ ! -f "$target" ]; then
    local found
    found="$(ls -1t "$ROOT"/backups/healthhub_*"$target"*.tar.gz 2>/dev/null | head -n 1)"
    [ -n "$found" ] || fail "No backup matches \"$target\". See the list with ./run.sh backups"
    target="$found"
  fi
  if [ "$YES" != 1 ]; then
    printf "\n  This REPLACES all current data and uploaded files with:\n    %s\n" "$(basename "$target")"
    printf "  Type \033[1mrestore\033[0m and press Enter to continue: "
    read -r ans || ans=""
    [ "$ans" = "restore" ] || fail "Nothing was changed."
  fi
  local was_running=0
  running && { was_running=1; stop_all_quiet; }
  rm -rf "$ROOT/Backend/media" "$DB_FILE"
  tar -xzf "$target" -C "$ROOT/Backend"
  ok "Restored $(basename "$target")"
  [ "$was_running" = 1 ] && warn "HealthHub was stopped for the restore. Start it again with ./run.sh --background" || true
}

wipe() {
  sqlite_only
  if [ -f "$DB_FILE" ]; then echo "  Saving a backup first…"; backup "before-wipe"; fi
  rm -f "$DB_FILE"
  find "$ROOT/Backend/media" -mindepth 2 -type f ! -name 'default.png' -delete 2>/dev/null || true
  ok "All data deleted"
}

# ---------------------------------------------------------------- setup steps
check_tools() {
  say "Checking tools"
  command -v python3 >/dev/null || fail "Python 3 is missing. Install it: sudo apt install -y python3 python3-venv python3-pip"
  python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)' || fail "Python 3.11 or newer is needed (you have $(python3 --version))."
  ok "$(python3 --version)"
  command -v node >/dev/null || fail "Node.js is missing. Install it:
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  sudo apt install -y nodejs"
  [ "$(node -p 'process.versions.node.split(".")[0]')" -ge 20 ] || fail "Node.js 20 or newer is needed (you have $(node -v))."
  ok "Node $(node -v)"
}

venv() {  # venv <folder> <requirements file> <import check>
  local dir="$1" req="$2" check="$3" py="$1/.venv/bin/python"
  if [ ! -x "$py" ]; then
    echo "  Creating a private Python folder in $(basename "$dir")/.venv…"
    python3 -m venv "$dir/.venv" || fail "Couldn't create .venv. Install the tool: sudo apt install -y python3-venv"
  fi
  if ! "$py" -c "$check" 2>/dev/null || [ "$dir/$req" -nt "$dir/.venv/.installed" ]; then
    echo "  Installing Python libraries (first time takes a minute)…"
    "$py" -m pip install -q --upgrade pip
    "$py" -m pip install -q -r "$dir/$req"
    touch "$dir/.venv/.installed"
  fi
}

# Every start (when there is data, you are at the keyboard and no data option was given) asks what to do with it.
choose_data() {
  [ "$RESET" != "" ] || [ "$KEEP" = 1 ] || [ "$BG" = 1 ] || [ ! -t 0 ] && return 0
  local users; users="$(user_count)"
  [ -n "$users" ] && [ "$users" != "0" ] || return 0
  echo
  echo "  You have data: $users accounts$(has_demo && echo ', including the demo')."
  echo "    1  Continue with it                      (just press Enter)"
  echo "    2  Start over with fresh demo data"
  echo "    3  Start over empty (only the admin account)"
  printf "  Choose 1, 2 or 3: "
  local c; read -r c || c=""
  case "$c" in
    2) RESET="demo" ;;
    3) RESET="empty" ;;
    *) ok "Continuing with your data"; return 0 ;;
  esac
  confirm_wipe
}

setup_backend() {
  say "Setting up the backend"
  venv "$ROOT/Backend" requirements.txt "import fastapi, sqlalchemy, alembic, aiosqlite"
  [ -f "$ROOT/Backend/.env" ] || cp "$ROOT/Backend/.env.example" "$ROOT/Backend/.env"
  ok "Python libraries ready"

  choose_data
  if [ "$RESET" != "" ]; then
    say "Starting over"
    wipe
  fi

  (cd "$ROOT/Backend" && "$BPY" -m alembic upgrade head >/dev/null 2>&1) || (cd "$ROOT/Backend" && "$BPY" -m alembic upgrade head)
  ok "Database tables up to date"

  local users ans=""
  users="$(user_count)"
  if [ "$RESET" = "demo" ]; then ans="y"
  elif [ "$RESET" = "empty" ]; then ans="n"
  elif [ -z "$users" ] || [ "$users" = "0" ]; then
    printf "\n  The database is empty. Load demo data? (hospitals, doctors, pharmacies, patients,\n"
    printf "  appointments, records and chats, all with Egyptian names and real Egyptian medicines) [Y/n] "
    read -r ans || ans=""
    [ -z "$ans" ] && ans="y"
  fi
  if [[ "$ans" =~ ^[Yy] ]]; then
    echo "  Loading demo data…"
    (cd "$ROOT/Backend" && "$BPY" -m app.seed --demo | tail -n 3)
  else
    (cd "$ROOT/Backend" && "$BPY" -m app.seed >/dev/null)
  fi
  ok "Data ready ($(user_count) accounts$(has_demo && echo ', with demo data'))"
}

setup_ai() {
  [ "$NO_AI" = 1 ] && return 0
  say "Setting up the drug interaction service"
  venv "$ROOT/AI" requirements.txt "import fastapi, pydantic_settings"
  [ -f "$ROOT/AI/.env" ] || cp "$ROOT/AI/.env.example" "$ROOT/AI/.env"
  if [ ! -f "$ROOT/AI/data/known_pairs.csv.gz" ]; then
    echo "  Downloading DrugBank's list of known interactions (one time only)…"
    (cd "$ROOT/AI" && "$APY" tools/fetch_data.py data) || { warn "Download failed. Interaction checks will say 'unknown' until the next ./run.sh"; NO_AI=1; return 0; }
  fi
  ok "Interaction service ready"
}

setup_web() {
  say "Setting up the website"
  cd "$ROOT/Web"
  if [ ! -d node_modules ] || [ package.json -nt node_modules/.installed ] || [ package-lock.json -nt node_modules/.installed ]; then
    echo "  Installing website libraries (first time takes a minute or two)…"
    npm install --no-audit --no-fund --loglevel=error
    touch node_modules/.installed
  fi
  ok "Website libraries ready"
  local stale=""
  [ -f dist/index.html ] && stale="$(find src public index.html vite.config.ts package.json -newer dist/index.html -type f -print -quit 2>/dev/null)"
  if [ "$MODE" = "prod" ] && { [ "$REBUILD" = 1 ] || [ ! -f dist/index.html ] || [ -n "$stale" ]; }; then
    echo "  Building the website (about 20 seconds)…"
    npx vite build >/dev/null || npx vite build
  fi
  cd "$ROOT"
}

# ---------------------------------------------------------------- Cloudflare Tunnel
CLOUDFLARED=""
find_cloudflared() {
  if command -v cloudflared >/dev/null; then CLOUDFLARED="$(command -v cloudflared)"; return 0; fi
  if [ -x "$ROOT/.tools/cloudflared" ]; then CLOUDFLARED="$ROOT/.tools/cloudflared"; return 0; fi
  local os arch
  os="$(uname -s)"; arch="$(uname -m)"
  if [ "$os" = "Darwin" ]; then
    command -v brew >/dev/null && { echo "  Installing cloudflared with Homebrew…"; brew install cloudflared; CLOUDFLARED="$(command -v cloudflared)"; return 0; }
    fail "cloudflared is missing. Install it: brew install cloudflared"
  fi
  case "$arch" in x86_64|amd64) arch=amd64 ;; aarch64|arm64) arch=arm64 ;; armv7l) arch=arm ;; *) fail "Download cloudflared for your computer from https://github.com/cloudflare/cloudflared/releases" ;; esac
  echo "  Downloading cloudflared, Cloudflare's tunnel program (one time only, about 40 MB)…"
  mkdir -p "$ROOT/.tools"
  curl -fL --progress-bar -o "$ROOT/.tools/cloudflared.part" \
    "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$arch" \
    || fail "Couldn't download cloudflared. Check the internet connection."
  chmod +x "$ROOT/.tools/cloudflared.part" && mv "$ROOT/.tools/cloudflared.part" "$ROOT/.tools/cloudflared"
  CLOUDFLARED="$ROOT/.tools/cloudflared"
}

TUNNEL_URL=""
start_tunnel() {
  [ "$TUNNEL" = 1 ] || return 0
  say "Opening the Cloudflare tunnel"
  find_cloudflared
  : >"$ROOT/logs/tunnel.log"
  local token
  token="$(conf_get TUNNEL_TOKEN)"
  if [ -n "$token" ]; then
    TUNNEL_TOKEN="$token" $LAUNCH "$CLOUDFLARED" tunnel --no-autoupdate run >>"$ROOT/logs/tunnel.log" 2>&1 </dev/null &
    TUNNEL_PID=$!
    TUNNEL_URL="$(conf_get SITE_URL)"
    sleep 4
    kill -0 $TUNNEL_PID 2>/dev/null || { tail -n 15 "$ROOT/logs/tunnel.log"; fail "The tunnel didn't start. The lines above (logs/tunnel.log) say why. Check the token."; }
    ok "Your tunnel is connected${TUNNEL_URL:+: $TUNNEL_URL}"
    [ -n "$TUNNEL_URL" ] || warn "Tell the script your address once: ./run.sh --site https://health.your-domain.com"
  else
    $LAUNCH "$CLOUDFLARED" tunnel --no-autoupdate --url "http://localhost:$WEB_PORT" >>"$ROOT/logs/tunnel.log" 2>&1 </dev/null &
    TUNNEL_PID=$!
    for _ in $(seq 1 30); do
      TUNNEL_URL="$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' "$ROOT/logs/tunnel.log" | head -n 1)"
      [ -n "$TUNNEL_URL" ] && break
      kill -0 $TUNNEL_PID 2>/dev/null || break
      sleep 1
    done
    [ -n "$TUNNEL_URL" ] || { tail -n 15 "$ROOT/logs/tunnel.log"; warn "No tunnel address yet. HealthHub still runs on this computer. See logs/tunnel.log"; return 0; }
    echo "$TUNNEL_URL" >"$ROOT/logs/tunnel.url"
    ok "Public address: $TUNNEL_URL"
  fi
}

# ---------------------------------------------------------------- start / stop
stop_all_quiet() {
  if [ -f "$PIDS" ]; then
    while read -r _ pid; do [ -n "$pid" ] && killtree "$pid"; done <"$PIDS"
  fi
  for port in $API_PORT $AI_PORT $WEB_PORT; do
    for pid in $(ss -ltnpH "sport = :$port" 2>/dev/null | grep -o 'pid=[0-9]*' | cut -d= -f2 | sort -u); do killtree "$pid"; done
  done
  pkill -f "$ROOT/.tools/cloudflared" 2>/dev/null || true
  [ -f "$PIDS" ] && grep -q '^tunnel ' "$PIDS" && pkill -f "cloudflared tunnel --no-autoupdate" 2>/dev/null || true
  for _ in $(seq 1 15); do running || break; sleep 1; done
  rm -f "$PIDS" "$ROOT/logs/tunnel.url"
}

stop_healthhub() {
  if running || [ -f "$PIDS" ]; then stop_all_quiet; ok "HealthHub stopped"; else ok "HealthHub wasn't running"; fi
  if running; then fail "Something still uses port $API_PORT or $WEB_PORT. See: ss -ltnp | grep -E ':($API_PORT|$WEB_PORT)'"; fi
}

# This computer's address on the Wi-Fi / home network (what phones use to reach it)
lan_ip() {
  local ip=""
  ip="$(ip route get 1.1.1.1 2>/dev/null | grep -o 'src [0-9.]*' | awk '{print $2}')"
  [ -z "$ip" ] && ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
  [ -z "$ip" ] && command -v ipconfig >/dev/null && ip="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)"
  echo "${ip:-<this-PC-IP>}"
}
# The address the Android app should use: the tunnel when one is open, otherwise the Wi-Fi address
app_url() {
  if [ -f "$ROOT/logs/tunnel.url" ]; then cat "$ROOT/logs/tunnel.url"
  elif [ -n "$(conf_get TUNNEL_TOKEN)" ] && [ -n "$(conf_get SITE_URL)" ] && port_up $WEB_PORT; then conf_get SITE_URL
  else echo "http://$(lan_ip):$WEB_PORT"; fi
}
firewall_hint() {
  if command -v ufw >/dev/null && ufw status 2>/dev/null | grep -q "Status: active" && ! ufw status 2>/dev/null | grep -q "^$WEB_PORT"; then
    echo "  │  ! Your firewall may block phones. Open the port once: sudo ufw allow $WEB_PORT"
  fi
}

print_box() {
  row() { printf "  │  %-14s %s\n" "$1" "$2"; }
  echo
  echo "  ┌───────────────────────────────────────────────────────────"
  echo "  │  HealthHub is running"
  echo "  │"
  [ -n "$TUNNEL_URL" ] && row "Website" "$TUNNEL_URL"
  row "On this PC" "http://localhost:$WEB_PORT"
  if [ "$LAN" = 1 ]; then row "On your Wi-Fi" "http://$(lan_ip):$WEB_PORT"; else row "On your Wi-Fi" "off (--local-only)"; fi
  row "API docs" "http://localhost:$API_PORT/docs"
  [ "$NO_AI" = 1 ] || row "AI service" "http://localhost:$AI_PORT/docs"
  row "Android app" "$(app_url)"
  [ "$LAN" = 1 ] && firewall_hint
  if has_demo; then
    echo "  │"
    echo "  │  Demo password = the role + @12345"
    row "  Patient" "patient@healthhub.local    Patient@12345"
    row "  Doctor" "doctor@healthhub.local     Doctor@12345"
    row "  Pharmacy" "pharmacy@healthhub.local   Pharmacy@12345"
    row "  Hospital" "hospital@healthhub.local   Hospital@12345"
    row "  Support" "support@healthhub.local    Support@12345"
    row "  Admin" "admin@healthhub.local      Admin@12345"
    echo "  │  All $(user_count) accounts: ./run.sh accounts"
  fi
  echo "  │"
  echo "  │  Logs:  ./run.sh logs        Status: ./run.sh status"
  echo "  │  App on your phone: ./run.sh app   (APK file: ./run.sh app apk)"
  if [ "$BG" = 1 ]; then echo "  │  Runs in the background. Stop it with: ./run.sh stop"
  else echo "  │  Press Ctrl+C to stop."; fi
  echo "  └───────────────────────────────────────────────────────────"
}

start_healthhub() {
  if running; then fail "HealthHub is already running. Stop it with ./run.sh stop, or use ./run.sh restart."; fi
  check_tools
  setup_backend
  setup_ai
  setup_web

  say "Starting HealthHub"
  mkdir -p "$ROOT/logs"
  LAUNCH=""; [ "$BG" = 1 ] && LAUNCH="setsid nohup"
  local reload="" host="127.0.0.1"
  [ "$MODE" = "dev" ] && reload="--reload"
  [ "$LAN" = 1 ] && host="0.0.0.0"
  AI_PID=""; TUNNEL_PID=""
  if [ "$NO_AI" != 1 ]; then
    (cd "$ROOT/AI" && exec $LAUNCH "$APY" -m uvicorn ddi_service.main:app --host 127.0.0.1 --port $AI_PORT --log-level warning) >>"$ROOT/logs/ai.log" 2>&1 </dev/null &
    AI_PID=$!
    export ML_SERVICE_URL="http://127.0.0.1:$AI_PORT"
  fi
  (cd "$ROOT/Backend" && exec $LAUNCH "$BPY" -m uvicorn app.main:app --host 127.0.0.1 --port $API_PORT --log-level warning $reload) >>"$ROOT/logs/api.log" 2>&1 </dev/null &
  API_PID=$!
  export VITE_PROXY_TARGET="http://127.0.0.1:$API_PORT"
  local site; site="$(conf_get SITE_URL)"
  [ -n "$site" ] && export VITE_ALLOWED_HOSTS="$(echo "$site" | sed -E 's#^https?://##; s#/.*$##')"
  if [ "$MODE" = "dev" ]; then
    (cd "$ROOT/Web" && exec $LAUNCH npx vite --host $host --port $WEB_PORT --strictPort) >>"$ROOT/logs/web.log" 2>&1 </dev/null &
  else
    (cd "$ROOT/Web" && exec $LAUNCH npx vite preview --host $host --port $WEB_PORT --strictPort) >>"$ROOT/logs/web.log" 2>&1 </dev/null &
  fi
  WEB_PID=$!
  { echo "api $API_PID"; echo "web $WEB_PID"; [ -n "$AI_PID" ] && echo "ai $AI_PID"; } >"$PIDS"

  stop_all() { stop_all_quiet; }
  [ "$BG" = 1 ] || trap 'echo; echo "Stopping HealthHub…"; stop_all; wait 2>/dev/null; exit 0' INT TERM

  for _ in $(seq 1 60); do port_up $API_PORT && port_up $WEB_PORT && break; sleep 1; done
  if ! port_up $API_PORT; then echo; tail -n 20 "$ROOT/logs/api.log"; stop_all; fail "The API didn't start. The lines above (logs/api.log) say why."; fi
  if ! port_up $WEB_PORT; then echo; tail -n 20 "$ROOT/logs/web.log"; stop_all; fail "The website didn't start. The lines above (logs/web.log) say why."; fi
  ok "API, website$([ "$NO_AI" = 1 ] || echo ' and interaction service') are up"

  start_tunnel
  [ -n "$TUNNEL_PID" ] && echo "tunnel $TUNNEL_PID" >>"$PIDS"

  print_box
  [ "$BG" = 1 ] && exit 0
  wait
  rm -f "$PIDS"
}

# ---------------------------------------------------------------- read the command and options
CMD="start"
case "${1:-}" in
  start|stop|restart|status|logs|backup|backups|restore|reset|demo|tunnel|update|test|app|accounts|help) CMD="$1"; shift ;;
  -h|--help) CMD="help"; shift ;;
esac

MODE="prod"; REBUILD=0; RESET=""; KEEP=0; BG=0; YES=0; DEMO=0; NO_AI=0; LAN=1; TUNNEL=0; ARGS=()
[ -n "$(conf_get TUNNEL_TOKEN)" ] && [ "$(conf_get TUNNEL_ALWAYS)" = 1 ] && TUNNEL=1
while [ $# -gt 0 ]; do
  case "$1" in
    --dev) MODE="dev" ;;
    --rebuild) REBUILD=1 ;;
    --keep) KEEP=1; RESET="" ;;
    --reset-demo) RESET="demo" ;;
    --reset-empty) RESET="empty" ;;
    --demo) DEMO=1 ;;
    --background|--bg) BG=1 ;;
    --yes|-y) YES=1 ;;
    --no-ai) NO_AI=1 ;;
    --lan) LAN=1 ;;
    --local-only) LAN=0 ;;
    --tunnel) TUNNEL=1 ;;
    --tunnel-token)
      [ -n "${2:-}" ] || fail "--tunnel-token needs the token from the Cloudflare dashboard"
      conf_set TUNNEL_TOKEN "$2"; conf_set TUNNEL_ALWAYS 1; TUNNEL=1; shift ;;
    --site)
      [ -n "${2:-}" ] || fail "--site needs an address, like: ./run.sh --site https://health.example.com"
      [[ "$2" =~ ^https?:// ]] || fail "The site address must start with https://"
      conf_set SITE_URL "${2%/}"; shift ;;
    -h|--help) CMD="help" ;;
    -*) fail "Unknown option: $1 (try ./run.sh help)" ;;
    *) ARGS+=("$1") ;;
  esac
  shift
done

if [ "$RESET" != "" ] && [[ "$CMD" == start || "$CMD" == restart ]]; then confirm_wipe; fi

case "$CMD" in
  help) show_help ;;
  start) start_healthhub ;;
  stop) stop_healthhub ;;
  restart) say "Restarting HealthHub"; stop_healthhub; BG=1; start_healthhub ;;

  status)
    say "HealthHub status"
    if port_up $API_PORT && port_up $WEB_PORT; then ok "Running (website $WEB_PORT, API $API_PORT$(port_up $AI_PORT && echo ", AI $AI_PORT"))"
    elif running; then warn "Only half running. Try ./run.sh restart"
    else warn "Not running. Start it with ./run.sh or ./run.sh --background"; fi
    echo "  On this PC   http://localhost:$WEB_PORT"
    echo "  On your Wi-Fi http://$(lan_ip):$WEB_PORT"
    echo "  Android app  $(app_url)"
    if [ -f "$ROOT/logs/tunnel.url" ]; then echo "  Internet     $(cat "$ROOT/logs/tunnel.url")"
    elif [ -n "$(conf_get TUNNEL_TOKEN)" ]; then echo "  Tunnel       your own tunnel${SITE_URL:+ }$(conf_get SITE_URL)"
    else echo "  Tunnel       off (start with --tunnel to get a public address)"; fi
    echo; stats
    ls "$ROOT"/backups/healthhub_*.tar.gz >/dev/null 2>&1 && echo "  Last backup    $(ls -1t "$ROOT"/backups/healthhub_*.tar.gz | head -n 1 | xargs basename)" || true
    ;;

  logs)
    mkdir -p "$ROOT/logs"
    case "${ARGS[0]:-all}" in
      api) f=("$ROOT/logs/api.log") ;;
      ai) f=("$ROOT/logs/ai.log") ;;
      web) f=("$ROOT/logs/web.log") ;;
      tunnel) f=("$ROOT/logs/tunnel.log") ;;
      all) f=("$ROOT/logs/api.log" "$ROOT/logs/ai.log" "$ROOT/logs/web.log" "$ROOT/logs/tunnel.log") ;;
      *) fail "Pick api, ai, web or tunnel. Example: ./run.sh logs api" ;;
    esac
    touch "${f[@]}"
    echo "Showing new log lines as they come in. Press Ctrl+C to stop watching (HealthHub keeps running)."
    tail -n 30 -f "${f[@]}" ;;

  backup) backup "${ARGS[@]}" ;;
  backups) say "Backups (newest first)"; list_backups; echo; echo "  Restore one with: ./run.sh restore latest   or   ./run.sh restore <part of the name>" ;;
  restore) restore "${ARGS[@]}" ;;

  reset)
    confirm_wipe
    wipe
    if [ "$DEMO" = 1 ]; then
      [ -x "$BPY" ] || fail "Run ./run.sh once first to set things up."
      (cd "$ROOT/Backend" && "$BPY" -m alembic upgrade head >/dev/null && "$BPY" -m app.seed --demo | tail -n 3)
    else
      echo "  The next ./run.sh asks whether to load demo data."
    fi
    running && warn "HealthHub is still running. Run ./run.sh restart" || true ;;

  demo)
    [ -x "$BPY" ] || fail "Run ./run.sh once first to set things up."
    has_demo && { ok "Demo data is already loaded"; exit 0; }
    say "Adding the demo data (nothing is deleted)"
    (cd "$ROOT/Backend" && "$BPY" -m alembic upgrade head >/dev/null && "$BPY" -m app.seed --demo | tail -n 3)
    accounts ;;

  tunnel)
    case "${ARGS[0]:-}" in
      off) conf_set TUNNEL_TOKEN ""; conf_set TUNNEL_ALWAYS ""; ok "Saved tunnel token forgotten. ./run.sh --tunnel now uses a free temporary address." ;;
      *) echo "  Start with a tunnel: ./run.sh --tunnel     Forget your own tunnel: ./run.sh tunnel off" ;;
    esac ;;

  accounts) say "Accounts"; accounts ;;

  app)
    command -v flutter >/dev/null || fail "Flutter is missing. Install it from https://docs.flutter.dev/get-started/install, then run ./run.sh app again."
    running || warn "HealthHub isn't running, so the app will have nothing to talk to. Start it first: ./run.sh --background"
    url="$(app_url)"
    say "Android app pointed at $url"
    export API_BASE_URL="$url"
    case "${ARGS[0]:-run}" in
      run) (cd "$ROOT/Flutter/healthhub" && ./run.sh run) ;;
      apk)
        (cd "$ROOT/Flutter/healthhub" && ./run.sh apk)
        apk="$ROOT/Flutter/healthhub/build/app/outputs/flutter-apk/app-release.apk"
        [ -f "$apk" ] && { mkdir -p "$ROOT/dist"; cp "$apk" "$ROOT/dist/HealthHub.apk"; ok "APK ready: dist/HealthHub.apk (copy it to your phone and open it)"; } ;;
      *) fail "Use ./run.sh app   or   ./run.sh app apk" ;;
    esac ;;

  test)
    say "Backend tests";  (cd "$ROOT/Backend" && ./run.sh test)
    say "AI tests";       (cd "$ROOT/AI" && ./run.sh test)
    say "Website tests";  (cd "$ROOT/Web" && ./run.sh test)
    ok "All tests passed" ;;

  update)
    command -v git >/dev/null || fail "git is missing. Install it: sudo apt install -y git"
    say "Downloading the newest code"
    git pull --rebase --autostash || fail "git couldn't update. Run: git status"
    ok "Code is up to date"
    if running; then stop_healthhub; REBUILD=1; BG=1; start_healthhub; else echo "  Start it with: ./run.sh --rebuild"; fi ;;
esac
