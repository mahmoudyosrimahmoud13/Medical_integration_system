"""Pharmacies, hospitals, prescription share codes and CT scan uploads."""

import secrets
import uuid
from datetime import datetime, timedelta, timezone
from decimal import Decimal

from fastapi import UploadFile
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import PHONE_REGEX
from app.models import (
    AdminLog,
    Appointment,
    Area,
    CTScan,
    Doctor,
    Drug,
    Hospital,
    HospitalDoctor,
    NotificationType,
    PasswordResetToken,
    Pharmacy,
    PharmacyDrug,
    Role,
    User,
)
from app.services.auth import add_role, get_user_by_email
from app.services.common import (
    DOCUMENT_EXTENSIONS,
    ServiceError,
    notify,
    now_local,
    save_upload,
)
from app.services.medical import current_prescriptions

SHARE_PURPOSE = "rx_share"
SHARE_MINUTES = 30


def _check_facility_fields(name: str, phone: str | None) -> None:
    if len((name or "").strip()) < 3:
        raise ServiceError("Name must be at least 3 characters")
    if phone and not PHONE_REGEX.match(phone) and not phone.replace("+", "").replace("-", "").isdigit():
        raise ServiceError("Invalid phone number")


# ================================================================ pharmacies


async def pharmacy_of(db: AsyncSession, user: User) -> Pharmacy | None:
    return await db.scalar(select(Pharmacy).where(Pharmacy.owner_id == user.id))


async def apply_pharmacy(db: AsyncSession, user: User, *, name: str, area_id: uuid.UUID, address: str, phone: str | None) -> Pharmacy:
    _check_facility_fields(name, phone)
    if await db.get(Area, area_id) is None:
        raise ServiceError("Unknown area")
    ph = await pharmacy_of(db, user)
    if ph and ph.accepted:
        raise ServiceError("Your pharmacy is already accepted")
    if ph is None:
        ph = Pharmacy(owner_id=user.id)
        db.add(ph)
    ph.name, ph.area_id, ph.address_description, ph.phone = name.strip(), area_id, (address or "").strip(), phone
    ph.accepted, ph.rejected, ph.date_of_request = False, False, datetime.now(timezone.utc)
    await db.commit()
    return await db.scalar(select(Pharmacy).where(Pharmacy.id == ph.id).execution_options(populate_existing=True))


async def accepted_pharmacy(db: AsyncSession, user: User) -> Pharmacy:
    ph = await pharmacy_of(db, user)
    if ph is None or not ph.accepted:
        raise ServiceError("Pharmacy not found or not accepted yet", 403)
    return ph


async def stock(db: AsyncSession, pharmacy: Pharmacy) -> list[PharmacyDrug]:
    rows = await db.scalars(select(PharmacyDrug).where(PharmacyDrug.pharmacy_id == pharmacy.id))
    return sorted(rows.all(), key=lambda r: r.drug.name.lower())


async def set_stock(db: AsyncSession, pharmacy: Pharmacy, drug_id: str, quantity: int, price: float) -> PharmacyDrug:
    if quantity < 0 or price < 0:
        raise ServiceError("Quantity and price can't be negative")
    if await db.get(Drug, drug_id) is None:
        raise ServiceError("Unknown drug")
    row = await db.scalar(select(PharmacyDrug).where(PharmacyDrug.pharmacy_id == pharmacy.id, PharmacyDrug.drug_id == drug_id))
    if row is None:
        row = PharmacyDrug(pharmacy_id=pharmacy.id, drug_id=drug_id)
        db.add(row)
    row.quantity, row.price = quantity, Decimal(str(price))
    await db.commit()
    return await db.scalar(select(PharmacyDrug).where(PharmacyDrug.id == row.id))


async def remove_stock(db: AsyncSession, pharmacy: Pharmacy, drug_id: str) -> None:
    row = await db.scalar(select(PharmacyDrug).where(PharmacyDrug.pharmacy_id == pharmacy.id, PharmacyDrug.drug_id == drug_id))
    if row is None:
        raise ServiceError("This drug is not in your stock", 404)
    await db.delete(row)
    await db.commit()


async def find_pharmacies(
    db: AsyncSession, *, drug_id: str | None, area_id: uuid.UUID | None, governorate_id: uuid.UUID | None
) -> list[tuple[Pharmacy, PharmacyDrug | None]]:
    """Accepted pharmacies, optionally only those that have `drug_id` in stock."""
    stmt = select(Pharmacy).join(Area).where(Pharmacy.accepted.is_(True))
    if area_id:
        stmt = stmt.where(Pharmacy.area_id == area_id)
    elif governorate_id:
        stmt = stmt.where(Area.governorate_id == governorate_id)
    pharmacies = list((await db.scalars(stmt.order_by(Pharmacy.name))).all())
    if not drug_id:
        return [(p, None) for p in pharmacies]
    items = await db.scalars(
        select(PharmacyDrug).where(PharmacyDrug.drug_id == drug_id, PharmacyDrug.quantity > 0, PharmacyDrug.pharmacy_id.in_([p.id for p in pharmacies]))
    )
    by_pharmacy = {i.pharmacy_id: i for i in items}
    return [(p, by_pharmacy[p.id]) for p in pharmacies if p.id in by_pharmacy]


# ================================================================ prescription share codes


async def create_share_code(db: AsyncSession, patient: User) -> tuple[str, datetime]:
    """A 6-character code the patient shows at the pharmacy, valid for 30 minutes."""
    alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    while True:
        code = "".join(secrets.choice(alphabet) for _ in range(6))
        if not await db.scalar(select(PasswordResetToken.id).where(PasswordResetToken.token == code)):
            break
    expires = datetime.now(timezone.utc) + timedelta(minutes=SHARE_MINUTES)
    db.add(PasswordResetToken(user_id=patient.id, token=code, purpose=SHARE_PURPOSE, expires_at=expires))
    await db.commit()
    return code, expires


async def prescriptions_by_code(db: AsyncSession, code: str):
    row = await db.scalar(
        select(PasswordResetToken).where(PasswordResetToken.token == (code or "").strip().upper(), PasswordResetToken.purpose == SHARE_PURPOSE)
    )
    if row is None:
        raise ServiceError("Invalid code", 404)
    expires = row.expires_at if row.expires_at.tzinfo else row.expires_at.replace(tzinfo=timezone.utc)
    if expires < datetime.now(timezone.utc):
        raise ServiceError("This code has expired, ask the patient for a new one")
    patient = await db.get(User, row.user_id)
    return patient, await current_prescriptions(db, patient.id)


# ================================================================ hospitals


async def hospital_of(db: AsyncSession, user: User) -> Hospital | None:
    return await db.scalar(select(Hospital).where(Hospital.owner_id == user.id))


async def apply_hospital(
    db: AsyncSession, user: User, *, name: str, area_id: uuid.UUID, address: str, phone: str | None, description: str
) -> Hospital:
    _check_facility_fields(name, phone)
    if await db.get(Area, area_id) is None:
        raise ServiceError("Unknown area")
    h = await hospital_of(db, user)
    if h and h.accepted:
        raise ServiceError("Your hospital is already accepted")
    if h is None:
        h = Hospital(owner_id=user.id)
        db.add(h)
    h.name, h.area_id, h.address_description, h.phone = name.strip(), area_id, (address or "").strip(), phone
    h.description = (description or "").strip()
    h.accepted, h.rejected, h.date_of_request = False, False, datetime.now(timezone.utc)
    await db.commit()
    return await db.scalar(select(Hospital).where(Hospital.id == h.id).execution_options(populate_existing=True))


async def accepted_hospital(db: AsyncSession, user: User) -> Hospital:
    h = await hospital_of(db, user)
    if h is None or not h.accepted:
        raise ServiceError("Hospital not found or not accepted yet", 403)
    return h


async def add_hospital_doctor(db: AsyncSession, hospital: Hospital, doctor_email: str, department: str) -> None:
    user = await get_user_by_email(db, doctor_email)
    doctor = await db.scalar(select(Doctor).where(Doctor.user_id == user.id)) if user else None
    if doctor is None or not doctor.accepted:
        raise ServiceError("No accepted doctor with this email", 404)
    link = await db.scalar(select(HospitalDoctor).where(HospitalDoctor.hospital_id == hospital.id, HospitalDoctor.doctor_id == doctor.id))
    if link is None:
        db.add(HospitalDoctor(hospital_id=hospital.id, doctor_id=doctor.id, department=(department or "").strip()))
        notify(db, doctor.user_id, NotificationType.REQUEST_RESULT, f"{hospital.name} added you to its doctors")
    else:
        link.department = (department or "").strip()
    await db.commit()


async def remove_hospital_doctor(db: AsyncSession, hospital: Hospital, doctor_id: uuid.UUID) -> None:
    link = await db.scalar(select(HospitalDoctor).where(HospitalDoctor.hospital_id == hospital.id, HospitalDoctor.doctor_id == doctor_id))
    if link is None:
        raise ServiceError("Doctor is not in this hospital", 404)
    await db.delete(link)
    await db.commit()


async def find_hospitals(db: AsyncSession, *, area_id=None, governorate_id=None, name: str | None = None) -> list[Hospital]:
    stmt = select(Hospital).join(Area).where(Hospital.accepted.is_(True))
    if area_id:
        stmt = stmt.where(Hospital.area_id == area_id)
    elif governorate_id:
        stmt = stmt.where(Area.governorate_id == governorate_id)
    if name:
        stmt = stmt.where(func.lower(Hospital.name).contains(name.strip().lower()))
    return list((await db.scalars(stmt.order_by(Hospital.name))).all())


async def hospital_appointments(db: AsyncSession, hospital: Hospital) -> list[Appointment]:
    ids = [link.doctor_id for link in hospital.doctors]
    if not ids:
        return []
    stmt = select(Appointment).where(
        Appointment.doctor_id.in_(ids), Appointment.status == "booked", Appointment.day >= now_local().date()
    )
    return list((await db.scalars(stmt.order_by(Appointment.day, Appointment.time_from))).all())


# ================================================================ admin review for pharmacies and hospitals


async def pending(db: AsyncSession, model) -> list:
    stmt = select(model).where(model.accepted.is_(False), model.rejected.is_(False)).order_by(model.date_of_request)
    return list((await db.scalars(stmt)).all())


async def review(db: AsyncSession, admin: User, model, item_id: uuid.UUID, accept: bool):
    item = await db.get(model, item_id)
    if item is None:
        raise ServiceError("Request not found", 404)
    item.accepted, item.rejected = accept, not accept
    role = Role.PHARMACY if model is Pharmacy else Role.HOSPITAL
    owner = await db.get(User, item.owner_id)
    if accept:
        await add_role(db, owner, role)
    kind = "pharmacy" if model is Pharmacy else "hospital"
    notify(db, owner.id, NotificationType.REQUEST_RESULT, f"Your {kind} request was {'accepted' if accept else 'rejected'}")
    db.add(AdminLog(admin_id=admin.id, action=f"{'accept' if accept else 'reject'}_{kind}", target=owner.email))
    await db.commit()
    return await db.get(model, item_id)


# ================================================================ CT scans


async def upload_ct(db: AsyncSession, patient: User, file: UploadFile) -> CTScan:
    name = await save_upload(file, "CTScans", DOCUMENT_EXTENSIONS)
    row = CTScan(patient_id=patient.id, file_name=name)
    db.add(row)
    await db.commit()
    return row


async def ct_scans(db: AsyncSession, patient_id: uuid.UUID) -> list[CTScan]:
    return list((await db.scalars(select(CTScan).where(CTScan.patient_id == patient_id).order_by(CTScan.uploaded_at.desc()))).all())
