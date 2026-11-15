import logging
from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles

from app.core.config import settings
from app.routers import legacy
from app.routers.v1 import admin, auth, catalog, doctors, facilities, patients
from app.services.common import ServiceError

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")

app = FastAPI(
    title=settings.app_name,
    version="2.0.0",
    description=(
        "HealthHub backend, rewritten in FastAPI.\n\n"
        "- **/api/v1** is the clean API for new clients.\n"
        "- **Legacy routes** (`/Auth`, `/Adress`, `/Hospital`, `/api/Notification`) reproduce the old ASP.NET API "
        "so the 2024 Flutter and React apps keep working."
    ),
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(ServiceError)
async def service_error_handler(_: Request, exc: ServiceError):
    return JSONResponse({"detail": exc.message}, status_code=exc.status_code)


@app.get("/health", tags=["health"])
async def health():
    return {"status": "ok"}


for r in (auth.router, catalog.router, doctors.router, patients.router, facilities.router, admin.router):
    app.include_router(r, prefix="/api/v1")
app.include_router(legacy.router)

# Uploaded images: http://host/Image/User/<file> and /Image/DoctorCertificates/<file> (same URLs as the old API)
Path(settings.media_dir).mkdir(parents=True, exist_ok=True)
app.mount("/Image", StaticFiles(directory=settings.media_dir), name="media")
