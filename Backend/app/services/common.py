"""Small shared helpers: errors, time parsing, file uploads, email, notifications."""

import logging
import re
import smtplib
import uuid
from datetime import date, datetime, time, timedelta
from email.message import EmailMessage
from pathlib import Path
from zoneinfo import ZoneInfo

from fastapi import UploadFile
from starlette.concurrency import run_in_threadpool

from app.core.config import settings
from app.models import Notification, NotificationType

log = logging.getLogger("healthhub")

WEEKDAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]


class ServiceError(Exception):
    """A business rule failed. `message` is safe to show to the user."""

    def __init__(self, message: str, status_code: int = 400):
        super().__init__(message)
        self.message = message
        self.status_code = status_code


# ---------------------------------------------------------------- time helpers

_AMPM = re.compile(r"^\s*(\d{1,2}):(\d{2})\s*([AaPp][Mm])\s*$")
_24H = re.compile(r"^\s*(\d{1,2}):(\d{2})(?::\d{2})?\s*$")


def parse_time(value: str | time) -> time:
    """Accepts '09:30 AM', '9:30 pm' or '21:30'. Raises ServiceError on bad input."""
    if isinstance(value, time):
        return value.replace(second=0, microsecond=0)
    m = _AMPM.match(value or "")
    if m:
        hour, minute, ampm = int(m[1]), int(m[2]), m[3].upper()
        if not (1 <= hour <= 12 and 0 <= minute < 60):
            raise ServiceError("Must Select xx:xx (AM|PM)")
        if ampm == "AM":
            hour = 0 if hour == 12 else hour
        else:
            hour = 12 if hour == 12 else hour + 12
        return time(hour, minute)
    m = _24H.match(value or "")
    if m:
        hour, minute = int(m[1]), int(m[2])
        if 0 <= hour < 24 and 0 <= minute < 60:
            return time(hour, minute)
    raise ServiceError("Must Select xx:xx (AM|PM)")


def format_ampm(t: time | None) -> str:
    return t.strftime("%I:%M %p") if t else ""


def plus_one_hour(t: time) -> time:
    return (datetime.combine(date(2000, 1, 1), t) + timedelta(hours=1)).time()


def parse_day(value: str | date | datetime) -> date:
    """Accepts '2024-06-12', '2024-06-12T00:00:00.000', '2024-06-12 00:00:00.000Z'."""
    if isinstance(value, datetime):
        return value.date()
    if isinstance(value, date):
        return value
    try:
        return date.fromisoformat(str(value).strip()[:10])
    except ValueError:
        raise ServiceError("Invalid date, use YYYY-MM-DD")


def day_name(d: date) -> str:
    return WEEKDAYS[d.weekday()]


def now_local() -> datetime:
    return datetime.now(ZoneInfo(settings.timezone)).replace(tzinfo=None)


def normalize_day_name(value: str) -> str:
    for d in WEEKDAYS:
        if d.lower() == (value or "").strip().lower():
            return d
    raise ServiceError(f"Day must be one of: {', '.join(WEEKDAYS)}")


# ---------------------------------------------------------------- uploads

IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp"}
DOCUMENT_EXTENSIONS = IMAGE_EXTENSIONS | {".pdf"}


async def save_upload(upload: UploadFile, folder: str, allowed: set[str] = IMAGE_EXTENSIONS) -> str:
    """Validates and stores an uploaded file under media/<folder>/. Returns the stored file name."""
    ext = Path(upload.filename or "").suffix.lower()
    if ext not in allowed:
        raise ServiceError(f"File type not allowed. Allowed: {', '.join(sorted(allowed))}")
    data = await upload.read()
    if not data:
        raise ServiceError("Uploaded file is empty")
    if len(data) > settings.max_upload_mb * 1024 * 1024:
        raise ServiceError(f"File is larger than {settings.max_upload_mb} MB")
    name = f"{uuid.uuid4().hex}{ext}"
    dest = Path(settings.media_dir) / folder
    dest.mkdir(parents=True, exist_ok=True)
    (dest / name).write_bytes(data)
    return name


# ---------------------------------------------------------------- email


def _smtp_send(to: str, subject: str, body: str) -> None:
    msg = EmailMessage()
    msg["From"] = settings.smtp_from
    msg["To"] = to
    msg["Subject"] = subject
    msg.set_content(body)
    with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=15) as smtp:
        smtp.starttls()
        if settings.smtp_user:
            smtp.login(settings.smtp_user, settings.smtp_password)
        smtp.send_message(msg)


async def send_email(to: str, subject: str, body: str) -> None:
    """Sends an email, or logs it when SMTP is not configured. Never raises."""
    if not settings.smtp_host:
        log.info("EMAIL (not sent, SMTP not configured) to=%s subject=%s\n%s", to, subject, body)
        return
    try:
        await run_in_threadpool(_smtp_send, to, subject, body)
    except Exception:  # noqa: BLE001 - email failure must not break the request
        log.exception("Failed to send email to %s", to)


# ---------------------------------------------------------------- notifications


def notify(db, user_id: uuid.UUID, type_: NotificationType, message: str, link: str | None = None) -> None:
    """Adds a notification to the session. The caller commits."""
    db.add(Notification(user_id=user_id, type=type_, message=message, link=link))
