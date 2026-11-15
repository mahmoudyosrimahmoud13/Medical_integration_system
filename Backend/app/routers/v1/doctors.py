import uuid
from datetime import date
from decimal import Decimal
from typing import Literal

from fastapi import APIRouter, File, Form, HTTPException, Query, Request, UploadFile
from sqlalchemy import select

from app.core.deps import DB, CurrentDoctor, CurrentUser
from app.models import Appointment, Review
from app.schemas.v1 import (
    AppointmentOut,
    BookedSlotOut,
    DoctorOut,
    DoctorPage,
    DoctorStatsOut,
    DoctorStatusOut,
    MessageOut,
    PriceIn,
    ReviewIn,
    ReviewOut,
    ScheduleDayIn,
    ScheduleDayOut,
    build_appointment,
    build_doctor,
    build_doctor_request,
    build_doctor_summary,
    build_schedule_day,
)
from app.services import auth as auth_svc
from app.services import booking
from app.services import doctors as svc
from app.services.common import day_name, format_ampm, plus_one_hour

router = APIRouter(prefix="/doctors", tags=["doctors"])


@router.get("", response_model=DoctorPage)
async def search(
    db: DB,
    request: Request,
    specialty_id: uuid.UUID | None = None,
    governorate_id: uuid.UUID | None = None,
    area_id: uuid.UUID | None = None,
    name: str | None = Query(None, min_length=2),
    sort: Literal["none", "join", "rate"] = "none",
    page: int = Query(0, ge=0),
):
    items, total = await svc.search_doctors(
        db, specialty_id=specialty_id, governorate_id=governorate_id, area_id=area_id, name=name, sort=sort, page=page
    )
    return DoctorPage(items=[build_doctor_summary(d, request) for d in items], total=total, page=page, page_size=len(items))


# ---- "me" routes come before /{doctor_id} so they are matched first


@router.post("/apply", response_model=DoctorStatusOut, status_code=201)
async def apply(
    user: CurrentUser,
    db: DB,
    request: Request,
    specialty_id: uuid.UUID = Form(...),
    area_id: uuid.UUID = Form(...),
    college_name: str = Form(...),
    graduation_year: date | None = Form(None),
    summary_career: str = Form(""),
    address_description: str = Form(""),
    certificates: list[UploadFile] = File(default=[]),
):
    doctor = await svc.apply_as_doctor(
        db,
        user,
        specialty_id=specialty_id,
        area_id=area_id,
        graduation_year=graduation_year,
        college_name=college_name,
        summary_career=summary_career,
        address_description=address_description,
        certificates=certificates,
    )
    return DoctorStatusOut(status="pending", doctor=build_doctor_request(doctor, request))


@router.get("/me/status", response_model=DoctorStatusOut)
async def my_status(user: CurrentUser, db: DB, request: Request):
    doctor = await svc.get_doctor_by_user(db, user.id)
    if doctor is None:
        return DoctorStatusOut(status="none")
    status = "accepted" if doctor.accepted else "rejected" if doctor.rejected else "pending"
    token = auth_svc.issue_token(user)[0] if doctor.accepted else None
    return DoctorStatusOut(status=status, doctor=build_doctor_request(doctor, request), access_token=token)


@router.get("/me/schedule", response_model=list[ScheduleDayOut])
async def my_schedule(doctor: CurrentDoctor):
    return [build_schedule_day(s) for s in doctor.schedule]


@router.put("/me/schedule", response_model=list[ScheduleDayOut])
async def replace_schedule(days: list[ScheduleDayIn], doctor: CurrentDoctor, db: DB):
    await svc.replace_schedule(db, doctor, [(d.day_name, d.time_from, d.time_to) for d in days])
    await db.refresh(doctor, ["schedule"])
    return [build_schedule_day(s) for s in doctor.schedule]


@router.delete("/me/schedule/{day}", response_model=MessageOut)
async def remove_day(day: str, doctor: CurrentDoctor, db: DB):
    await svc.remove_schedule_day(db, doctor, day)
    return MessageOut(message="Removed")


@router.put("/me/price", response_model=MessageOut)
async def set_price(body: PriceIn, doctor: CurrentDoctor, db: DB):
    await svc.change_price(db, doctor, Decimal(str(body.price)))
    return MessageOut(message="Price updated")


@router.get("/me/appointments", response_model=list[AppointmentOut])
async def my_appointments(doctor: CurrentDoctor, db: DB, request: Request, upcoming_only: bool = True):
    rows = await booking.doctor_appointments(db, doctor, upcoming_only)
    return [build_appointment(a, request, with_doctor=False, with_patient=True) for a in rows]


@router.delete("/me/appointments/{appointment_id}", response_model=MessageOut)
async def cancel_patient(appointment_id: uuid.UUID, doctor: CurrentDoctor, db: DB):
    appt = await db.get(Appointment, appointment_id)
    if not await booking.cancel_by_doctor(db, doctor, appt):
        raise HTTPException(404, "Appointment not found")
    return MessageOut(message="Cancelled, the patient was notified")


@router.get("/me/stats", response_model=DoctorStatsOut)
async def my_stats(doctor: CurrentDoctor, db: DB):
    stats = await svc.patient_stats(db, doctor)
    upcoming = len(await booking.doctor_appointments(db, doctor))
    return DoctorStatsOut(
        total=stats["total"],
        male=stats["male"],
        female=stats["female"],
        male_percentage=stats["malePercentage"],
        female_percentage=stats["femalePercentage"],
        upcoming_appointments=upcoming,
    )


# ---- public doctor routes


@router.get("/{doctor_id}", response_model=DoctorOut)
async def get_one(doctor_id: uuid.UUID, db: DB, request: Request):
    doctor = await svc.get_doctor(db, doctor_id)
    if doctor is None:
        raise HTTPException(404, "Doctor not found")
    return build_doctor(doctor, request)


@router.get("/{doctor_id}/booked-slots", response_model=list[BookedSlotOut])
async def booked_slots(doctor_id: uuid.UUID, db: DB, day: date | None = None):
    rows = await booking.booked_slots(db, doctor_id, day)
    return [
        BookedSlotOut(day=a.day, day_name=day_name(a.day), time_from=format_ampm(a.time_from), time_to=format_ampm(plus_one_hour(a.time_from)))
        for a in rows
    ]


@router.get("/{doctor_id}/reviews", response_model=list[ReviewOut])
async def reviews(doctor_id: uuid.UUID, db: DB):
    rows = await db.scalars(select(Review).where(Review.doctor_id == doctor_id).order_by(Review.sent_at.desc()))
    return [ReviewOut.build(r) for r in rows]


@router.post("/{doctor_id}/reviews", response_model=ReviewOut)
async def add_review(doctor_id: uuid.UUID, body: ReviewIn, user: CurrentUser, db: DB):
    review = await svc.rate_doctor(db, user, doctor_id, body.rate, body.message)
    review = await db.scalar(select(Review).where(Review.id == review.id))
    return ReviewOut.build(review)
