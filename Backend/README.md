# HealthHub Backend (FastAPI)

The HealthHub API, rewritten from the 2024 ASP.NET backend into Python and FastAPI.

It serves two kinds of clients:

- **`/api/v1/...`**: the new, clean API. The new Flutter app and web frontend use it.
- **Legacy routes** (`/Auth/...`, `/Adress/...`, `/Hospital/...`, `/api/Notification`): the same paths, field
  names and behavior as the old ASP.NET API, so the 2024 apps (`flutter_final` and `forntend` branches) still work.

## Quick start

| What you want | Linux / macOS | Windows |
|---|---|---|
| See all options | `./run.sh help` | `run.bat help` |
| Install everything | `./run.sh setup` | `run.bat setup` |
| Run for development (demo data, auto reload) | `./run.sh dev` | `run.bat dev` |
| Run the tests | `./run.sh test` | `run.bat test` |
| Start fresh (delete local database) | `./run.sh reset` | `run.bat reset` |
| Run with PostgreSQL in Docker | `./run.sh docker` | `run.bat docker` |

After `dev` starts, open **http://localhost:8020/docs** for the interactive API docs.

You need Python 3.11 or newer. Docker is only needed for the `docker` option.

### Demo data (created by `dev`, `reset`, and `seed --demo`)

The demo database is meant to look like a real deployment, in two layers that only ever add:

- `app/demo.py`, the base: 20 doctors in 9 governorates, 5 hospitals, 9 pharmacies, 35 patients and the
  main demo accounts (doctor@, patient@, ...), which always have the same history.
- `app/demo_more.py`, on top: 40 more doctors so all 27 governorates are covered, 9 hospitals, 21
  pharmacies, 115 patients (some children), a year of visits with follow-ups and readings, cancelled and
  upcoming bookings, reviews and chats in English and Egyptian Arabic, and notifications.

`python -m app.seed --demo-if-loaded` adds the newest demo data only if a demo is already loaded (run.sh
does this when you continue with your data). Demo accounts share one password per role: `Role@12345`.

The product catalogue (`seed_data/egypt_products.csv`) holds 165 branded medicines sold in Egypt
(Panadol, Cataflam, Augmentin, Glucophage, Concor, Lipitor, Amaryl, Zithromax, Flagyl, ...) with
manufacturer, strength, form, pack, category, indicative EGP price and whether a prescription is needed.
Each product links to its active ingredient in the 1,700-drug DrugBank list, so prescriptions,
pharmacy stock and the interaction check all work on ingredients while people search by brand.
Prices are approximate and for demo use only.

Main logins (password is the role name + `@12345`):

| Role | Email | Password |
|---|---|---|
| Admin | admin@healthhub.local | Admin@12345 |
| Doctor (Dr. Ahmed Hassan, Cardiology, Maadi) | doctor@healthhub.local | Doctor@12345 |
| Patient (Sara Ali) | patient@healthhub.local | Patient@12345 |
| Pharmacy (El Nour Pharmacy, Maadi) | pharmacy@healthhub.local | Pharmacy@12345 |
| Hospital (Dar El Shifa) | hospital@healthhub.local | Hospital@12345 |

Other demo doctors: mona.elsayed@, khaled.mostafa@, yasmin.fouad@, omar.abdel@, nour.ibrahim@,
mahmoud.adel@, dina.samir@, tarek.nabil@, heba.mahmoud@, amr.lotfy@, salma.youssef@healthhub.local.

## Roles and what each one can do

- **Patient**: search doctors and hospitals, book, move and cancel appointments, rate doctors, see the full
  medical record (sessions, prescriptions, diseases, CT scans), make a 30-minute code to share prescriptions
  with a pharmacy, find pharmacies that have a drug in stock.
- **Doctor**: apply with certificates, set a weekly schedule and price, see booked patients, cancel a booking,
  write medical sessions with prescriptions, read a patient's full record, check drug interactions.
- **Pharmacy**: apply, manage stock (quantity and price per drug), read a patient's current prescriptions with
  the patient's share code.
- **Hospital**: apply, add doctors to departments, see the upcoming appointments of its doctors.
- **Admin / Customer Service**: accept or reject doctor, pharmacy and hospital requests, add or remove roles,
  block users, add specialties.

## Messaging

`/api/v1/chat`. There is no cold messaging; every conversation comes from a real relationship:

| Who | Can start a conversation with |
|---|---|
| Patient | a doctor they booked with; any accepted pharmacy or hospital; support |
| Doctor | their patients; hospitals they work at; other doctors at the same hospital; support |
| Hospital | its own doctors; support |
| Pharmacy | nobody (patients start, the pharmacy replies); support |
| Admin | anyone |

Once a conversation exists both sides can keep writing. Reading a conversation marks the other side's
messages as read, and every new message creates a notification for the other person.
`GET /chat/contacts` lists the people the current user may write to, with the reason (e.g. "visit on 2026-01-05").

## Project layout

```
app/
  core/        settings, password and token handling, "who is logged in" checks
  db/          database connection
  models/      database tables
  schemas/     request and response shapes for /api/v1
  services/    the business rules (booking, search, records, pharmacies, hospitals)
  routers/
    v1/        the clean API
    legacy.py  the old ASP.NET routes
  ml/          client for the drug interaction model
  seed.py      loads governorates, areas, specialties, 1,700 drugs and the admin
  demo.py      the rich demo: products, doctors, hospitals, pharmacies, patients, records, chats
alembic/       database migrations
seed_data/     reference data copied from the 2024 project
tests/         API tests (legacy Flutter calls, doctor flows, pharmacies, hospitals, chat, products)
```

## Settings

Copy `.env.example` to `.env` (setup does this for you). The main ones:

- `DATABASE_URL`: SQLite by default. Use `postgresql+asyncpg://...` for PostgreSQL.
- `JWT_SECRET`: change it in production, at least 32 random characters.
- `SMTP_*`: leave `SMTP_HOST` empty and emails (password reset codes) are printed in the console.
- `ML_SERVICE_URL`: address of the drug interaction service in `../AI` (for example `http://localhost:8001`). Empty means interaction checks answer "unknown".

## Booking rules (same as the old backend)

A slot is one hour. A booking is refused when:

1. the doctor doesn't work that weekday
2. the time is outside the doctor's hours, or already in the past
3. the patient already has an upcoming appointment with this doctor
4. the patient has another appointment at the same day and time
5. another patient already holds that hour with this doctor

## What changed from the old backend

- Booking checks are limited to the same doctor (the old code blocked the same hour across all doctors).
- Cancelled appointments are kept with status `cancelled` instead of deleted.
- Patients can only read their own profile through `/Auth/GetUser`.
- `POST /Auth/ForgetPassword {email}` now really sends a reset code (the old route needed a login, so it never worked from the app).
- New: pharmacies, hospitals, CT scan uploads, prescription share codes, full medical record endpoint.
