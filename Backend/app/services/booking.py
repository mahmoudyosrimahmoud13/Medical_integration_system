"""Appointment booking rules, ported from the old PatientDatesService.

A slot is one hour long. Checks, in order:
1. the doctor exists and is accepted
2. the doctor works on that weekday
3. the start time sits inside the day's window, and the slot is not in the past
4. (new bookings) the patient has no other upcoming appointment with this doctor
5. the patient has no other appointment at the same day and time
6. no other patient holds the same hour with this doctor on that day
"""

import uuid
from datetime import date, datetime, time

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Appointment, Doctor, NotificationType, User
from app.services.common import (
    ServiceError,
    day_name,
    format_ampm,
    notify,
    now_local,
    plus_one_hour,
)
from app.services.doctors import get_doctor

BOOKED = "booked"


async def _check_slot(
    db: AsyncSession, *, patient: User, doctor: Doctor, day: date, start: time, exclude_id: uuid.UUID | None, new_booking: bool
) -> None:
    if doctor.user_id == patient.id:
        raise ServiceError("You can't book an appointment with yourself")

    window = next((s for s in doctor.schedule if s.day_name == day_name(day)), None)
    if window is None:
        raise ServiceError("Choose The Appropriate Day")
    if not (window.time_from <= start and plus_one_hour(start) <= window.time_to) and not (
        window.time_from <= start < window.time_to and window.time_to == time(23, 59)
    ):
        raise ServiceError("Choose The Appropriate Time")
    if datetime.combine(day, start) <= now_local():
        raise ServiceError("Choose The Appropriate Time")

    base = select(Appointment).where(Appointment.status == BOOKED)
    if exclude_id:
        base = base.where(Appointment.id != exclude_id)

    if new_booking:
        upcoming = await db.scalar(
            base.where(
                Appointment.patient_id == patient.id, Appointment.doctor_id == doctor.id, Appointment.day >= now_local().date()
            ).limit(1)
        )
        if upcoming:
            raise ServiceError("You already have an upcoming appointment with this doctor")

    same_time = await db.scalar(
        base.where(Appointment.patient_id == patient.id, Appointment.day == day, Appointment.time_from == start).limit(1)
    )
    if same_time:
        raise ServiceError("You Have An Appointment With Another Doctor\nCheck Your Appointments")

    taken = await db.scalars(base.where(Appointment.doctor_id == doctor.id, Appointment.day == day))
    for other in taken:
        if other.time_from < plus_one_hour(start) and start < plus_one_hour(other.time_from):
            raise ServiceError("this date was Previously Selected")


async def book(db: AsyncSession, patient: User, doctor_id: uuid.UUID, day: date, start: time) -> Appointment:
    doctor = await get_doctor(db, doctor_id)
    if doctor is None:
        raise ServiceError("Must Select Doctor", 404)
    await _check_slot(db, patient=patient, doctor=doctor, day=day, start=start, exclude_id=None, new_booking=True)
    appt = Appointment(patient_id=patient.id, doctor_id=doctor.id, day=day, time_from=start, status=BOOKED)
    db.add(appt)
    await db.commit()
    return await db.scalar(select(Appointment).where(Appointment.id == appt.id))


async def reschedule(db: AsyncSession, patient: User, appointment_id: uuid.UUID, day: date, start: time) -> Appointment:
    appt = await db.scalar(
        select(Appointment).where(
            Appointment.id == appointment_id, Appointment.patient_id == patient.id, Appointment.status == BOOKED
        )
    )
    if appt is None:
        raise ServiceError("Must Select Date", 404)
    await _check_slot(db, patient=patient, doctor=appt.doctor, day=day, start=start, exclude_id=appt.id, new_booking=False)
    appt.day, appt.time_from = day, start
    await db.commit()
    return appt


async def cancel_by_patient(db: AsyncSession, patient: User, appointment_id: uuid.UUID) -> bool:
    appt = await db.scalar(
        select(Appointment).where(
            Appointment.id == appointment_id, Appointment.patient_id == patient.id, Appointment.status == BOOKED
        )
    )
    if appt is None or datetime.combine(appt.day, appt.time_from) < now_local():
        return False
    appt.status = "cancelled"
    await db.commit()
    return True


async def cancel_by_doctor(db: AsyncSession, doctor: Doctor, appointment: Appointment | None) -> bool:
    if appointment is None or appointment.doctor_id != doctor.id or appointment.status != BOOKED:
        return False
    appointment.status = "cancelled"
    notify(
        db,
        appointment.patient_id,
        NotificationType.DOCTOR_CANCELLED_YOUR_TIME,
        f"Dr. {doctor.user.name} cancelled your appointment on {appointment.day} at {format_ampm(appointment.time_from)}",
    )
    await db.commit()
    return True


async def patient_appointments(db: AsyncSession, patient: User, upcoming_only: bool = True) -> list[Appointment]:
    stmt = select(Appointment).where(Appointment.patient_id == patient.id, Appointment.status == BOOKED)
    if upcoming_only:
        stmt = stmt.where(Appointment.day >= now_local().date())
    return list((await db.scalars(stmt.order_by(Appointment.day, Appointment.time_from))).all())


async def doctor_appointments(db: AsyncSession, doctor: Doctor, upcoming_only: bool = True) -> list[Appointment]:
    stmt = select(Appointment).where(Appointment.doctor_id == doctor.id, Appointment.status == BOOKED)
    if upcoming_only:
        stmt = stmt.where(Appointment.day >= now_local().date())
    return list((await db.scalars(stmt.order_by(Appointment.day, Appointment.time_from))).all())


async def booked_slots(db: AsyncSession, doctor_id: uuid.UUID, day: date | None = None) -> list[Appointment]:
    """Taken slots for a doctor (no patient info is exposed by the routers)."""
    stmt = select(Appointment).where(
        Appointment.doctor_id == doctor_id, Appointment.status == BOOKED, Appointment.day >= now_local().date()
    )
    if day:
        stmt = stmt.where(Appointment.day == day)
    return list((await db.scalars(stmt.order_by(Appointment.day, Appointment.time_from))).all())
