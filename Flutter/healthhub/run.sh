#!/usr/bin/env bash
# HealthHub Flutter app helper. Run ./run.sh help to see the options.
set -e
cd "$(dirname "$0")"

API="${API_BASE_URL:-}"
DEFINE=()
[ -n "$API" ] && DEFINE=(--dart-define=API_BASE_URL="$API")

setup() {
  echo ">> Creating platform folders (android, ios, web, desktop) if missing"
  flutter create . --project-name healthhub --org com.healthhub --platforms=android,ios,web,windows,linux,macos >/dev/null
  echo ">> Applying HealthHub name, bundle id and permissions"
  dart run tool/patch_platforms.dart
  echo ">> Getting packages"
  flutter pub get
  echo ">> Generating app icons"
  dart run flutter_launcher_icons >/dev/null || echo "   (icons skipped: run 'dart run flutter_launcher_icons' later)"
  echo ">> Setup done. Try: ./run.sh run"
}

ensure() { [ -d android ] || setup; }

case "${1:-help}" in
  setup)   setup ;;
  run)     ensure; shift; flutter run "${DEFINE[@]}" "$@" ;;
  web)     ensure; flutter run -d chrome "${DEFINE[@]}" ;;
  test)    flutter pub get >/dev/null; shift; flutter test "$@" ;;
  analyze) flutter pub get >/dev/null; flutter analyze ;;
  format)  dart format lib test tool ;;
  apk)     ensure; flutter build apk --release "${DEFINE[@]}"; echo ">> build/app/outputs/flutter-apk/app-release.apk" ;;
  appbundle) ensure; flutter build appbundle --release "${DEFINE[@]}" ;;
  ios)     ensure; flutter build ipa --release "${DEFINE[@]}" ;;
  build-web) ensure; flutter build web --release "${DEFINE[@]}"; echo ">> build/web" ;;
  icons)   dart run flutter_launcher_icons ;;
  clean)   flutter clean; rm -rf android ios web windows linux macos; echo ">> Removed build output and generated platform folders" ;;
  *)
    cat <<'HELP'
Usage: ./run.sh <option>      (set API_BASE_URL=http://192.168.1.10:8020 to point at your backend)

  setup       create platform folders, apply the HealthHub identity, get packages, make icons
  run         run on the connected device or emulator (extra flags go to flutter run)
  web         run in Chrome
  test        run unit and widget tests
  analyze     static checks
  format      format the code
  apk         build a release Android APK
  appbundle   build a release Android App Bundle (Play Store)
  ios         build a release iOS archive (macOS only)
  build-web   build the web version
  icons       regenerate app icons from assets/logo/app_icon.png
  clean       remove build output and generated platform folders
HELP
    ;;
esac
