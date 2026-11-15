# HealthHub

One place for patients, doctors, hospitals and pharmacies in Egypt. Book a doctor, keep your
medical record, share prescriptions with a pharmacy by code, find a medicine nearby, message
your doctor, and check drug interactions.

Graduation project (2024), rebuilt in 2026 by Mahmoud Yosri.

| Folder        | What it is                                                     |
|---------------|----------------------------------------------------------------|
| `Backend/`    | FastAPI API (Python). Also keeps the old 2024 API paths working |
| `Web/`        | Website for every role, with a landing page (React)             |
| `Flutter/`    | Android / iOS app (Flutter). Built by GitHub Actions            |
| `AI/`         | Drug interaction service, plus the AI investigation (`AI/PLAN.md`) |
| `branding/`   | Logo files                                                     |

## Start everything with one command

Linux or macOS (needs Python 3.11+ and Node.js 20+):

```bash
./run.sh
```

Windows: `run.bat`

It sets up whatever is missing and starts the API, the AI service and the website on
http://localhost:8080. When you already have data it asks:

```
1  Continue with it                      (just press Enter)
2  Start over with fresh demo data
3  Start over empty (only the admin account)
```

A backup is saved before anything is deleted. See every option with `./run.sh help`.

### Demo accounts

The password is the role followed by `@12345`.

| Role     | Email                     | Password        |
|----------|---------------------------|-----------------|
| Patient  | patient@healthhub.local   | Patient@12345   |
| Doctor   | doctor@healthhub.local    | Doctor@12345    |
| Pharmacy | pharmacy@healthhub.local  | Pharmacy@12345  |
| Hospital | hospital@healthhub.local  | Hospital@12345  |
| Support  | support@healthhub.local   | Support@12345   |
| Admin    | admin@healthhub.local     | Admin@12345     |

The demo has 20 doctors in 9 governorates, 5 hospitals, 9 pharmacies with real Egyptian medicines,
35 patients, appointments, records, chats and notifications, plus 2 doctors, a hospital and a
pharmacy waiting for the admin to accept them. `./run.sh accounts` lists every login.

## Put it on the internet without a server (Cloudflare Tunnel)

```bash
./run.sh --tunnel --background
```

- You get a free https address like `https://blue-sky-123.trycloudflare.com`. No account needed.
- Open it on any phone or computer.
- In the Android app, paste it as the server address. The app asks for it the first time it opens; later, tap "Server" on the login screen or the profile page to change it.
- The address changes every time you start. For a fixed address on your own domain:
  1. Make a free Cloudflare account and add your domain.
  2. In the Cloudflare dashboard go to Zero Trust, then Networks, then Tunnels, and create a tunnel. Copy its token.
  3. Add a public hostname (for example `health.your-domain.com`) that points to `http://localhost:8080`.
  4. Run `./run.sh --tunnel-token <token> --site https://health.your-domain.com --background`.
     It is saved, so next time `./run.sh --background` is enough.

With Docker instead: `docker compose --profile tunnel up --build`, then read the address with
`docker compose logs tunnel`.

## Each part on its own

Every folder has its own `run.sh` / `run.bat` with options (`./run.sh help`) and its own README.

## Branches

| Branch       | What changed                                   |
|--------------|------------------------------------------------|
| `fastapi`    | backend rewritten in FastAPI                   |
| `flutter-v2` | Flutter app rebuilt (clean architecture, tests, new design) |
| `web-v2`     | web app rebuilt in React + TypeScript          |
| `ai`         | new drug interaction service and AI plan       |
| `master`     | everything together                            |

What is still left to do: [NEXT_STEPS.md](NEXT_STEPS.md).
