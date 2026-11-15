# What is not done yet

Updated 15 Nov 2026. In order of priority. (Done: richer demo data, Arabic, dark mode, the server address screen, the APK on GitHub Releases.)

## 1. Android app: medicine reminders
- Build them from the patient's current prescriptions. Let the patient pick the times and get a phone alert, even when the app is closed. Add a "taken" button.
- Packages: `flutter_local_notifications` + `timezone`. Add the Android notification and exact alarm permissions in `tool/patch_platforms.dart`.

## 2. Android app: phone notifications
- Today the app has only an in-app notifications list. Add phone notifications for new messages, bookings and prescriptions. Start by checking the notifications endpoint in the background (`workmanager`); add Firebase push later.

## 3. Clay design
- A light clay style is now on the patient home screen, the onboarding pictures and the empty states. Staff screens stay flat.
- Still to do: use it for the medicine reminders screen once that exists, and check it on a real phone in dark mode.

## 4. Web app
- Show where an interaction answer came from ("DrugBank" or "model estimate"), and add a "check with a pharmacist" line.
- More page tests (booking, messaging).

## 5. AI (details in AI/PLAN.md)
- Train the interaction model again and save its label list next to the weights. Calibrate the scores, and export to ONNX.
- Link every Egyptian brand to its active ingredients, including combination products.
- Bone fracture: train a new model on a public X-ray set. The 2024 model file was never in the repo.

## 6. Checks to run on a real machine
- `./run.sh --tunnel`: the tunnel could not be opened from the build machine. Check that the address shows up and that images load through it.
- `run.bat` on Windows: written but not run on Windows yet.
- On a real phone: the first-start server screen with a Cloudflare link, and the Arabic layout.
