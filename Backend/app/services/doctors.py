import uuid
from datetime import date, datetime, timezone
from decimal import Decimal

from fastapi import UploadFile
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models import (
    AdminLog,
    Appointment,
    Area,
    Doctor,
    DoctorCertificate,
    DoctorSchedule,
    NotificationType,
    Review,
    Role,
    Specialty,
    User,
)
from app.services.auth import add_role
from app.services.common import (
    DOCUMENT_EXTENSIONS,
    ServiceError,
    normalize_day_name,
    notify,
    parse_time,
    save_upload,
    send_email,
)


async def get_doctor(db: AsyncSession, doctor_id: uuid.UUID, accepted_only: bool = True) -> Doctor | None:
    stmt = select(Doctor).where(Doctor.id == doctor_id)
    if accepted_only:
        stmt = stmt.where(Doctor.accepted.is_(True))
    return await db.scalar(stmt)


async def get_doctor_by_user(db: AsyncSession, user_id: uuid.UUID) -> Doctor | None:
    return await db.scalar(select(Doctor).where(Doctor.user_id == user_id))


async def search_doctors(
    db: AsyncSession,
    *,
    specialty_id: uuid.UUID | None = None,
    area_id: uuid.UUID | None = None,
    governorate_id: uuid.UUID | None = None,
    name: str | None = None,
    sort: str = "none",  # none | join | rate
    page: int = 0,
    page_size: int | None = None,
) -> tuple[list[Doctor], int]:
    """Accepted doctors only. Area wins over governorate when both are given. Page is 0-based."""
    page_size = page_size or settings.page_size
    stmt = select(Doctor).join(Doctor.user).join(Doctor.area).where(Doctor.accepted.is_(True))
    if specialty_id:
        stmt = stmt.where(Doctor.specialty_id == specialty_id)
    if area_id:
        stmt = stmt.where(Doctor.area_id == area_id)
    elif governorate_id:
        stmt = stmt.where(Area.governorate_id == governorate_id)
    if name:
        stmt = stmt.where(func.lower(User.name).contains(name.strip().lower()))
    doctors = list((await db.scalars(stmt)).all())

    if sort == "join":
        doctors.sort(key=lambda d: d.date_of_join or datetime.min.replace(tzinfo=timezone.utc))
    elif sort == "rate":
        doctors.sort(key=lambda d: d.rating_stars, reverse=True)
    else:
        doctors.sort(key=lambda d: d.user.name.lower())

    total = len(doctors)
    start = max(page, 0) * page_size
    return doctors[start : start + page_size], total


async def apply_as_doctor(
    db: AsyncSession,
    user: User,
    *,
    specialty_id: uuid.UUID,
    area_id: uuid.UUID,
    graduation_year: date | None,
    college_name: str,
    summary_career: str,
    address_description: str,
    certificates: list[UploadFile],
) -> Doctor:
    existing = await get_doctor_by_user(db, user.id)
    if existing is not None and existing.accepted:
        raise ServiceError("You are already a doctor")
    if await db.get(Specialty, specialty_id) is None:
        raise ServiceError("Unknown specialty")
    if await db.get(Area, area_id) is None:
        raise ServiceError("Unknown clinic area")
    if not college_name.strip():
        raise ServiceError("College name is required")

    files = [await save_upload(f, "DoctorCertificates", DOCUMENT_EXTENSIONS) for f in certificates]

    doctor = existing or Doctor(user_id=user.id)
    doctor.specialty_id = specialty_id
    doctor.area_id = area_id
    doctor.graduation_year = graduation_year
    doctor.college_name = college_name.strip()
    doctor.summary_career = (summary_career or "").strip()
    doctor.address_description = (address_description or "").strip()
    doctor.accepted = False
    doctor.rejected = False
    doctor.date_of_request = datetime.now(timezone.utc)
    if existing is None:
        db.add(doctor)
    await db.flush()
    for name in files:
        db.add(DoctorCertificate(doctor_id=doctor.id, file_name=name))
    await db.commit()
    return await get_doctor(db, doctor.id, accepted_only=False)


async def pending_requests(db: AsyncSession, page: int = 0) -> tuple[list[Doctor], int]:
    stmt = select(Doctor).where(Doctor.accepted.is_(False), Doctor.rejected.is_(False)).order_by(Doctor.date_of_request)
    rows = list((await db.scalars(stmt)).all())
    size = settings.page_size
    return rows[page * size : page * size + size], len(rows)


async def review_request(db: AsyncSession, admin: User, doctor_id: uuid.UUID, accept: bool) -> Doctor:
    doctor = await get_doctor(db, doctor_id, accepted_only=False)
    if doctor is None:
        raise ServiceError("Doctor request not found", 404)
    doctor.accepted = accept
    doctor.rejected = not accept
    if accept:
        doctor.date_of_join = datetime.now(timezone.utc)
        await add_role(db, doctor.user, Role.DOCTOR)
    message = "Your Request has been Accepted" if accept else "Your Request has been rejected"
    notify(db, doctor.user_id, NotificationType.DOCTOR_REQUEST_RESULT, message)
    db.add(AdminLog(admin_id=admin.id, action="accept_doctor" if accept else "reject_doctor", target=doctor.user.email))
    await db.commit()
    await send_email(doctor.user.email, "HealthHub doctor request", f"Hello Dr. {doctor.user.name},\n\n{message}.\n")
    return doctor


# ---------------------------------------------------------------- schedule


def _validated_window(time_from: str, time_to: str):
    start, end = parse_time(time_from), parse_time(time_to)
    if end <= start:
        raise ServiceError("End time must be after start time")
    return start, end


async def set_schedule_day(
    db: AsyncSession, doctor: Doctor, day: str, time_from: str, time_to: str, old_day: str | None = None
) -> DoctorSchedule:
    day = normalize_day_name(day)
    start, end = _validated_window(time_from, time_to)
    target_day = normalize_day_name(old_day) if old_day else day

    row = await db.scalar(
        select(DoctorSchedule).where(DoctorSchedule.doctor_id == doctor.id, DoctorSchedule.day_name == target_day)
    )
    if old_day and row is None:
        raise ServiceError(f"You don't work on {target_day}")
    if day != target_day:
        clash = await db.scalar(
            select(DoctorSchedule.id).where(DoctorSchedule.doctor_id == doctor.id, DoctorSchedule.day_name == day)
        )
        if clash:
            raise ServiceError(f"{day} is already in your schedule")
    if row is None:
        row = DoctorSchedule(doctor_id=doctor.id, day_name=day, time_from=start, time_to=end)
        db.add(row)
    else:
        row.day_name, row.time_from, row.time_to = day, start, end
    await db.commit()
    return row


async def replace_schedule(db: AsyncSession, doctor: Doctor, days: list[tuple[str, str, str]]) -> None:
    seen = set()
    rows = []
    for day, f, t in days:
        d = normalize_day_name(day)
        if d in seen:
            raise ServiceError(f"{d} appears twice")
        seen.add(d)
        start, end = _validated_window(f, t)
        rows.append(DoctorSchedule(doctor_id=doctor.id, day_name=d, time_from=start, time_to=end))
    for old in await db.scalars(select(DoctorSchedule).where(DoctorSchedule.doctor_id == doctor.id)):
        await db.delete(old)
    await db.flush()
    db.add_all(rows)
    await db.commit()


async def remove_schedule_day(db: AsyncSession, doctor: Doctor, day: str) -> None:
    day = normalize_day_name(day)
    row = await db.scalar(
        select(DoctorSchedule).where(DoctorSchedule.doctor_id == doctor.id, DoctorSchedule.day_name == day)
    )
    if row is None:
        raise ServiceError(f"You don't work on {day}")
    await db.delete(row)
    await db.commit()


async def change_price(db: AsyncSession, doctor: Doctor, price: Decimal) -> None:
    if price < 0:
        raise ServiceError("Price can't be negative")
    doctor.price_session = price
    await db.commit()


# ---------------------------------------------------------------- reviews and stats


async def rate_doctor(db: AsyncSession, patient: User, doctor_id: uuid.UUID, rate: float, message: str) -> Review:
    doctor = await get_doctor(db, doctor_id)
    if doctor is None:
        raise ServiceError("Doctor not found", 404)
    if doctor.user_id == patient.id:
        raise ServiceError("You can't rate yourself")
    if not 0 <= rate <= 5:
        raise ServiceError("Rate must be between 0 and 5")
    booked = await db.scalar(
        select(Appointment.id).where(Appointment.patient_id == patient.id, Appointment.doctor_id == doctor.id).limit(1)
    )
    if not booked:
        raise ServiceError("You can only rate a doctor you booked with")
    review = await db.scalar(select(Review).where(Review.doctor_id == doctor.id, Review.patient_id == patient.id))
    if review is None:
        review = Review(doctor_id=doctor.id, patient_id=patient.id, rate=Decimal(str(rate)), message=message or "")
        db.add(review)
    else:
        review.rate, review.message = Decimal(str(rate)), message or ""
        review.sent_at = datetime.now(timezone.utc)
    notify(db, doctor.user_id, NotificationType.RATE_DOCTOR, f"{patient.name} rated you {rate:g}/5")
    await db.commit()
    return review


async def patient_stats(db: AsyncSession, doctor: Doctor) -> dict:
    """Distinct patients who booked this doctor, split by gender."""
    patients = (
        await db.scalars(
            select(User).join(Appointment, Appointment.patient_id == User.id).where(Appointment.doctor_id == doctor.id).distinct()
        )
    ).all()
    total = len(patients)
    male = sum(1 for p in patients if p.gender_male)
    return {
        "total": total,
        "male": male,
        "female": total - male,
        "malePercentage": round(male / total * 100, 2) if total else 0,
        "femalePercentage": round((total - male) / total * 100, 2) if total else 0,
    }
