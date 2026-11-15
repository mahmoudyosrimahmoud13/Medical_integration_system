# HealthHub Web

The browser version of HealthHub. One app with a workspace for every role:
patients, doctors, pharmacies, hospitals and admins. It talks to the FastAPI
backend in `../Backend`.

Built with React 18, TypeScript, Vite, Tailwind CSS 4, TanStack Query and Zustand.

## Run it

You need Node.js 20 or newer. On Windows use `run.bat` instead of `./run.sh`.

```bash
./run.sh full     # starts the API and the web app together
```

Then open http://localhost:5173 and log in with a demo account:

| Role     | Email                     | Password        |
|----------|---------------------------|-----------------|
| Patient  | patient@healthhub.local   | Patient@12345   |
| Doctor   | doctor@healthhub.local    | Doctor@12345    |
| Pharmacy | pharmacy@healthhub.local  | Pharmacy@12345  |
| Hospital | hospital@healthhub.local  | Hospital@12345  |
| Admin    | admin@healthhub.local     | Admin@12345     |

All options:

| Option    | What it does                                              |
|-----------|-----------------------------------------------------------|
| `setup`   | install packages and create `.env`                        |
| `dev`     | web app only, with live reload, on port 5173              |
| `full`    | API (`../Backend`) and web app together                   |
| `test`    | run the tests once                                        |
| `watch`   | run the tests again on every save                         |
| `check`   | check TypeScript types                                    |
| `build`   | build production files into `dist/`                       |
| `preview` | build, then serve `dist/` on port 4173                    |
| `docker`  | database + API + web in Docker on port 8080               |
| `clean`   | delete `node_modules` and `dist`                          |

## Settings

`.env` (copied from `.env.example` on setup):

- `VITE_PROXY_TARGET`: where the dev server sends `/api` and `/Image` calls. Default `http://localhost:8000`.
- `VITE_API_BASE_URL`: full API address for production builds. Leave empty when the API sits behind the same domain (the Docker setup does this with nginx).

## How the code is organised

```
src/
  app/         routes and the shell (sidebar, bottom bar, workspace switch)
  core/
    api/       the HTTP client, response types and one function per endpoint
    auth/      login state, saved in localStorage
    ui/        shared building blocks: Button, Card, Modal, Tabs, Stars, Skeleton...
    time.ts    booking slot rules, same as the server and the mobile app
  features/    one folder per area of the product
    landing/ auth/ home/ doctors/ appointments/ records/
    pharmacy/ hospital/ doctorPortal/ chat/ admin/
  test/        test setup and the fake API server (MSW)
```

Rules the code follows:

- Pages never call `fetch` directly. They use `core/api/endpoints.ts` through TanStack Query.
- Business rules (slots, validation) live in plain functions in `core/` and have unit tests.
- Every role sees only its own workspace. Logging in opens the newest role you have.

## Tests

```bash
./run.sh test
```

Unit tests cover the slot maths, form validation, the API client and the login
state. Page tests render real components against a fake API (MSW), for example
"a doctor lands on the doctor workspace after login".
