"""Patient-side routes: appointments, medical records, notifications. Plus the doctor's record-writing routes."""

import uuid

from fastapi import APIRouter, HTTPException, Request
from sqlalchemy import select

from app.core.deps import DB, CurrentDoctor, CurrentUser
from app.models import Notification
from app.schemas.v1 import (
    AppointmentOut,
    BookIn,
    DiseaseOut,
    InteractionCheckIn,
    InteractionCheckOut,
    MessageOut,
    NotificationOut,
    PrescriptionOut,
    RescheduleIn,
    SessionIn,
    SessionOut,
    build_appointment,
    build_session,
)
from app.services import booking, medical
from app.services.common import parse_time

router = APIRouter()


# ---------------------------------------------------------------- appointments


@router.post("/appointments", response_model=AppointmentOut, status_code=201, tags=["appointments"])
async def book(body: BookIn, user: CurrentUser, db: DB, request: Request):
    appt = await booking.book(db, user, body.doctor_id, body.day, parse_time(body.time_from))
    return build_appointment(appt, request)


@router.get("/appointments", response_model=list[AppointmentOut], tags=["appointments"])
async def my_appointments(user: CurrentUser, db: DB, request: Request, upcoming_only: bool = True):
    return [build_appointment(a, request) for a in await booking.patient_appointments(db, user, upcoming_only)]


@router.put("/appointments/{appointment_id}", response_model=AppointmentOut, tags=["appointments"])
async def reschedule(appointment_id: uuid.UUID, body: RescheduleIn, user: CurrentUser, db: DB, request: Request):
    appt = await booking.reschedule(db, user, appointment_id, body.day, parse_time(body.time_from))
    return build_appointment(appt, request)


@router.delete("/appointments/{appointment_id}", response_model=MessageOut, tags=["appointments"])
async def cancel(appointment_id: uuid.UUID, user: CurrentUser, db: DB):
    if not await booking.cancel_by_patient(db, user, appointment_id):
        raise HTTPException(400, "Appointment not found or already passed")
    return MessageOut(message="Cancelled")


# ---------------------------------------------------------------- medical records (patient)


@router.get("/medical/sessions", response_model=list[SessionOut], tags=["medical records"])
async def my_sessions(user: CurrentUser, db: DB, request: Request):
    return [build_session(s, request) for s in await medical.patient_sessions(db, user.id)]


@router.get("/medical/prescriptions/current", response_model=list[PrescriptionOut], tags=["medical records"])
async def my_current_prescriptions(user: CurrentUser, db: DB):
    return [PrescriptionOut.build(p) for p in await medical.current_prescriptions(db, user.id)]


@router.get("/medical/diseases", response_model=list[DiseaseOut], tags=["medical records"])
async def my_diseases(user: CurrentUser, db: DB):
    return [DiseaseOut.build(d) for d in await medical.patient_diseases(db, user.id)]


# ---------------------------------------------------------------- medical records (doctor)


@router.post("/medical/sessions", response_model=SessionOut, status_code=201, tags=["medical records"])
async def write_session(body: SessionIn, doctor: CurrentDoctor, db: DB, request: Request):
    session = await medical.create_session(
        db,
        doctor,
        patient_email=body.patient_email,
        disease_name=body.disease_name,
        session_notes=body.session_notes,
        disease_notes=body.disease_notes,
        persistent=body.persistent,
        cured=body.cured,
        prescriptions=[medical.PrescriptionInput(**p.model_dump()) for p in body.prescriptions],
    )
    return build_session(session, request)


@router.get("/medical/patients/{patient_email}/sessions", response_model=list[SessionOut], tags=["medical records"])
async def patient_record(patient_email: str, doctor: CurrentDoctor, db: DB, request: Request):
    return [build_session(s, request) for s in await medical.sessions_with_doctor(db, doctor, patient_email)]


@router.post("/medical/interactions/check", response_model=InteractionCheckOut, tags=["medical records"])
async def check_interactions(body: InteractionCheckIn, doctor: CurrentDoctor, db: DB):
    return await medical.check_interactions(db, body.patient_email, body.drug_ids)


# ---------------------------------------------------------------- notifications


@router.get("/notifications", response_model=list[NotificationOut], tags=["notifications"])
async def notifications(user: CurrentUser, db: DB, unread_only: bool = False):
    stmt = select(Notification).where(Notification.user_id == user.id)
    if unread_only:
        stmt = stmt.where(Notification.is_read.is_(False))
    rows = await db.scalars(stmt.order_by(Notification.created_at.desc()).limit(100))
    return [NotificationOut.build(n) for n in rows]


@router.post("/notifications/{notification_id}/read", response_model=MessageOut, tags=["notifications"])
async def mark_read(notification_id: uuid.UUID, user: CurrentUser, db: DB):
    n = await db.get(Notification, notification_id)
    if n is None or n.user_id != user.id:
        raise HTTPException(404, "Notification not found")
    n.is_read = True
    await db.commit()
    return MessageOut(message="OK")
