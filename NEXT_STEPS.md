# What is not done yet

Saved on 15 Nov 2026, when work stopped. In order of priority.

## 1. Android app: medicine reminders
- Build them from the patient's current prescriptions. Let the patient pick the times and get a phone alert, even when the app is closed. Add a "taken" button.
- Packages: `flutter_local_notifications` + `timezone`. Add the Android notification and exact alarm permissions in `tool/patch_platforms.dart`.

## 2. Android app: phone notifications
- Today the app has only an in-app notifications list. Add phone notifications for new messages, bookings and prescriptions. Start by checking the notifications endpoint in the background (`workmanager`); add Firebase push later.

## 3. Android app: server address setting
- Add a "Server address" field on the login screen, saved on the phone, so a Cloudflare tunnel link can be pasted in without rebuilding the app.
- Today the address is fixed at build time (`--dart-define=API_BASE_URL=...`), so build with the tunnel address for now.

## 4. Richer demo data
- Started, not finished, and left out of this version on purpose:
  - 8 more doctors in Mansoura, Tanta, Zagazig, Assiut, Hurghada and Ismailia
  - 2 more hospitals and 3 more pharmacies
  - 20 more patients
  - a customer support account (`support@healthhub.local`)
  - doctor, hospital and pharmacy applications waiting for the admin
  - more chats and notifications
  - a fixed history for Sara Ali (on warfarin, so the interaction check finds something)
- Place: `Backend/app/demo.py`. After it lands, list the new accounts in the README and in the `run.sh` summary box. (The box already mentions `support@`, which doesn't exist yet.)

## 5. Web app
- Show where an interaction answer came from ("DrugBank" or "model estimate"), and add a "check with a pharmacist" line.
- More page tests (booking, messaging).

## 6. AI (details in AI/PLAN.md)
- Train the interaction model again and save its label list next to the weights. Calibrate the scores, and export to ONNX.
- Link every Egyptian brand to its active ingredients, including combination products.
- Bone fracture: train a new model on a public X-ray set. The 2024 model file was never in the repo.

## 7. Checks to run on a real machine
- `./run.sh --tunnel`: the tunnel could not be opened from the build machine. Check that the address shows up and that images load through it.
- `run.bat` on Windows: written but not run on Windows yet.
- The Flutter build runs only in GitHub Actions. Check the first run of the "Flutter" workflow, then download the APK from the run's artifacts.
