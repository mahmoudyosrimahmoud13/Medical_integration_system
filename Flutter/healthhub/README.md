# HealthHub mobile app (Flutter)

The HealthHub app, rebuilt from the 2024 prototype with a clean architecture, tests, a new design and
four workspaces: patient, doctor, pharmacy and hospital (plus admin review).

## Quick start

You need the Flutter SDK 3.35 or newer and the backend running (see `Backend/README.md`).

| What you want | Linux / macOS | Windows |
|---|---|---|
| See all options | `./run.sh help` | `run.bat help` |
| First-time setup | `./run.sh setup` | `run.bat setup` |
| Run on a device or emulator | `./run.sh run` | `run.bat run` |
| Run in Chrome | `./run.sh web` | `run.bat web` |
| Run the tests | `./run.sh test` | `run.bat test` |
| Build an Android APK | `./run.sh apk` | `run.bat apk` |

The platform folders (`android/`, `ios/`, `web/`, ...) are not in git. `setup` generates them with
`flutter create` and then applies the HealthHub name, bundle id, permissions and icons. The GitHub Actions
workflow does the same, so the repo stays small and the generated code never goes stale.

### Pointing the app at your backend

By default the app talks to `http://localhost:8020` (or `http://10.0.2.2:8020` on the Android emulator,
which is how the emulator reaches your computer). For a real phone on the same Wi-Fi, use your computer's IP:

```
API_BASE_URL=http://192.168.1.10:8020 ./run.sh run
```

Demo accounts come from the backend seed: `patient@healthhub.local` / `Patient@12345`,
`doctor@healthhub.local` / `Doctor@12345`, `pharmacy@...`, `hospital@...`, `admin@...`.

## How the code is organised

```
lib/
  main.dart, app.dart        start-up, theme, the gate that picks splash / onboarding / login / home
  core/
    network/                 ApiClient (Dio) and ApiException (server errors as plain messages)
    storage/                 TokenStorage (login token, onboarding flag, chosen workspace)
    state/                   LoadCubit and ActionCubit: loading / data / error for simple screens
    theme/                   colors and Material 3 theme
    widgets/                 shared widgets and the animation helpers
    utils/                   validators, time-slot logic, JSON helpers
    di.dart                  Deps: every repository in one object
  features/<feature>/
    domain/                  entities + the repository interface (no Flutter, no Dio)
    data/                    the repository implementation that calls the API
    presentation/            cubits and screens
```

Each feature depends only on its `domain` and on `core`. Screens never call Dio directly, they go through
a repository, so tests swap repositories for fakes (see `test/fakes.dart`).

## Tests

```
flutter test
```

- `time_slots_test`: the booking slot maths (hourly slots, overlaps, past hours).
- `validators_test`: the form rules, same as the server.
- `api_exception_test`: how server errors turn into messages.
- `doctor_search_cubit_test`, `session_cubit_test`: state logic with fake repositories.
- `widgets/`: login flow, doctor search, and booking end to end on fake data.

## Animations

- Page transitions fade and slide up (`core/navigation/app_route.dart`).
- Lists use a staggered entrance (`.entrance(index)`), cards shrink on press (`Pressable`), loading shows a
  shimmer skeleton, success shows a spring "pop".
- Day and time pickers in the booking sheet animate their selection; the share code has a 30-minute ring.

## Workspaces

A user can have several roles. The profile tab switches workspace; each workspace has its own tabs:

| Workspace | Tabs |
|---|---|
| Patient | Home, Doctors, Visits, Record, Messages, Profile |
| Doctor | Today (bookings + stats), Patients (records, new visit, interaction check), Schedule, Messages, Profile |
| Pharmacy | Counter (patient share codes), Stock, Messages, Profile |
| Hospital | Hospital (doctors by department, appointments), Messages, Profile |
| Admin | Requests (doctors, pharmacies, hospitals), Messages, Profile |

## Messaging

Every workspace has an inbox. Who can start a conversation follows the backend rules: a patient can write to
a doctor they booked with, to any pharmacy or hospital, and to support; doctors to their patients and
hospitals; hospitals to their doctors. "Message" buttons sit on the doctor, pharmacy and hospital pages, and
the "New message" screen lists everyone you may write to, grouped by relationship. Open threads refresh
every few seconds.
