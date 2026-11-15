import uuid
from dataclasses import dataclass
from datetime import date

from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.ml.client import check_pair, describe
from app.models import (
    Disease,
    Doctor,
    Drug,
    MedicalSession,
    NotificationType,
    Prescription,
    User,
)
from app.services.auth import get_user_by_email
from app.services.common import ServiceError, notify, now_local


@dataclass
class PrescriptionInput:
    drug_id: str
    note: str | None = None
    repeat: str | None = None
    repeat_count: int = 1
    start_date: date | None = None
    end_date: date | None = None


async def _patient(db: AsyncSession, email: str) -> User:
    patient = await get_user_by_email(db, email)
    if patient is None:
        raise ServiceError("Patient not found", 404)
    return patient


async def _drugs(db: AsyncSession, ids: list[str]) -> dict[str, Drug]:
    ids = [i.strip() for i in ids if i and i.strip()]
    found = {d.id: d for d in (await db.scalars(select(Drug).where(Drug.id.in_(ids)))).all()} if ids else {}
    missing = [i for i in ids if i not in found]
    if missing:
        raise ServiceError(f"Unknown drug id: {', '.join(missing)}")
    return found


async def create_session(
    db: AsyncSession,
    doctor: Doctor,
    *,
    patient_email: str,
    disease_name: str,
    session_notes: str | None,
    disease_notes: str | None,
    persistent: bool,
    cured: bool,
    prescriptions: list[PrescriptionInput],
) -> MedicalSession:
    patient = await _patient(db, patient_email)
    if patient.id == doctor.user_id:
        raise ServiceError("You can't write a session for yourself")
    if not (disease_name or "").strip():
        raise ServiceError("Disease name is required")
    await _drugs(db, [p.drug_id for p in prescriptions])
    for p in prescriptions:
        if p.repeat_count < 1:
            raise ServiceError("repeatCount must be at least 1")
        if p.start_date and p.end_date and p.end_date < p.start_date:
            raise ServiceError("End date must be after start date")

    disease = await db.scalar(
        select(Disease).where(Disease.patient_id == patient.id, func.lower(Disease.name) == disease_name.strip().lower())
    )
    if disease is None:
        disease = Disease(patient_id=patient.id, name=disease_name.strip())
        db.add(disease)
    disease.persistent = persistent
    disease.cured = cured
    disease.notes = disease_notes
    disease.responsible_doctor_id = doctor.id

    session = MedicalSession(
        doctor_id=doctor.id, patient_id=patient.id, disease_name=disease_name.strip(), notes=session_notes
    )
    db.add(session)
    await db.flush()
    for p in prescriptions:
        db.add(
            Prescription(
                session_id=session.id,
                drug_id=p.drug_id.strip(),
                note=p.note,
                repeat=p.repeat,
                repeat_count=p.repeat_count,
                start_date=p.start_date,
                end_date=p.end_date,
            )
        )
    notify(db, patient.id, NotificationType.NEW_PRESCRIPTION, f"Dr. {doctor.user.name} added a new prescription for you")
    await db.commit()
    return await db.scalar(select(MedicalSession).where(MedicalSession.id == session.id).execution_options(populate_existing=True))


async def patient_sessions(db: AsyncSession, patient_id: uuid.UUID) -> list[MedicalSession]:
    stmt = select(MedicalSession).where(MedicalSession.patient_id == patient_id).order_by(MedicalSession.session_date.desc())
    return list((await db.scalars(stmt)).all())


async def sessions_with_doctor(db: AsyncSession, doctor: Doctor, patient_email: str) -> list[MedicalSession]:
    """Everything this patient's record holds. A doctor sees the full history, not only their own sessions."""
    patient = await _patient(db, patient_email)
    return await patient_sessions(db, patient.id)


async def current_prescriptions(db: AsyncSession, patient_id: uuid.UUID) -> list[Prescription]:
    today = now_local().date()
    stmt = (
        select(Prescription)
        .join(MedicalSession)
        .where(MedicalSession.patient_id == patient_id, or_(Prescription.end_date.is_(None), Prescription.end_date >= today))
    )
    return list((await db.scalars(stmt)).all())


async def patient_diseases(db: AsyncSession, patient_id: uuid.UUID) -> list[Disease]:
    return list((await db.scalars(select(Disease).where(Disease.patient_id == patient_id).order_by(Disease.name))).all())


async def check_interactions(db: AsyncSession, patient_email: str, new_drug_ids: list[str]) -> dict:
    """Checks the new drugs against each other and against the patient's current drugs."""
    patient = await _patient(db, patient_email)
    new = await _drugs(db, new_drug_ids)
    current = {p.drug_id: p.drug for p in await current_prescriptions(db, patient.id)}

    pairs, seen = [], set()
    new_list = list(new.values())
    for i, a in enumerate(new_list):
        for b in new_list[i + 1 :] + [d for k, d in current.items() if k not in new]:
            key = tuple(sorted([a.id, b.id]))
            if a.id != b.id and key not in seen:
                seen.add(key)
                pairs.append((a, b))

    results, available, impact = [], True, False
    for a, b in pairs:
        row = await check_pair(db, a, b)
        if row is None:
            available = False
            results.append({"drugA": a.name, "drugB": b.name, "interacts": None, "interactionType": None, "description": "Unknown: interaction model not available"})
            continue
        impact = impact or row.interacts
        results.append(
            {"drugA": a.name, "drugB": b.name, "interacts": row.interacts, "interactionType": row.interaction_type, "description": describe(row)}
        )
    return {"available": available, "impact": impact, "results": results}
