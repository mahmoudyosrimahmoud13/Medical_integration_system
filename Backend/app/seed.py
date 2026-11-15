"""Loads reference data and the first admin.

    python -m app.seed            # governorates, areas, specialties, drugs, admin user
    python -m app.seed --demo     # also a demo doctor and a demo patient, for trying the apps

Safe to run more than once: rows that already exist are skipped.
"""

import argparse
import asyncio
import csv
import json
import shutil
from datetime import date, datetime, time, timezone
from decimal import Decimal
from pathlib import Path

from sqlalchemy import select

from app.core.config import BASE_DIR, settings
from app.core.security import hash_password
from app.db.session import SessionLocal
from app.models import (
    Area,
    Doctor,
    DoctorSchedule,
    Drug,
    Governorate,
    Hospital,
    HospitalDoctor,
    Pharmacy,
    PharmacyDrug,
    Role,
    Specialty,
    User,
    UserRole,
)

SEED_DIR = BASE_DIR / "seed_data"


def _phpmyadmin_rows(path: Path) -> list[dict]:
    """The governorates/cities files are phpMyAdmin JSON exports: find the table block and return its rows."""
    for block in json.loads(path.read_text(encoding="utf-8")):
        if isinstance(block, dict) and block.get("type") == "table":
            return block["data"]
    return []


async def seed_reference(db) -> None:
    existing_gov = {g.key: g for g in (await db.scalars(select(Governorate))).all()}
    gov_by_old_id = {}
    for row in _phpmyadmin_rows(SEED_DIR / "governorates.json"):
        key = row["governorate_name_en"].strip()
        gov = existing_gov.get(key)
        if gov is None:
            gov = Governorate(key=key, name_ar=row["governorate_name_ar"].strip())
            db.add(gov)
        gov_by_old_id[row["id"]] = gov
    await db.flush()

    existing_areas = {(a.governorate_id, a.key) for a in (await db.scalars(select(Area))).all()}
    added_areas = 0
    for row in _phpmyadmin_rows(SEED_DIR / "cities.json"):
        gov = gov_by_old_id.get(row["governorate_id"])
        key = row["city_name_en"].strip()
        if gov is None or (gov.id, key) in existing_areas:
            continue
        existing_areas.add((gov.id, key))
        db.add(Area(key=key, name_ar=row["city_name_ar"].strip(), governorate_id=gov.id))
        added_areas += 1

    existing_spec = {s.name for s in (await db.scalars(select(Specialty))).all()}
    for row in json.loads((SEED_DIR / "Specialties.json").read_text(encoding="utf-8")):
        name = row["Name"].strip()
        if name not in existing_spec:
            existing_spec.add(name)
            db.add(Specialty(name=name))

    existing_drugs = set((await db.scalars(select(Drug.id))).all())
    with open(SEED_DIR / "drugs_name.csv", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            if row["drug_id"] not in existing_drugs and row["smiles"]:
                existing_drugs.add(row["drug_id"])
                db.add(Drug(id=row["drug_id"], name=row["name"].strip(), smiles=row["smiles"].strip()))

    await db.commit()
    print(f"Reference data ready: {len(gov_by_old_id)} governorates, +{added_areas} areas, "
          f"{len(existing_spec)} specialties, {len(existing_drugs)} drugs")


async def _user(db, *, email, password, name, roles, area, phone, national_id, male=True) -> User:
    user = await db.scalar(select(User).where(User.email == email))
    if user:
        return user
    user = User(
        email=email,
        username=email.split("@")[0],
        password_hash=hash_password(password),
        name=name,
        phone=phone,
        national_id=national_id,
        birth_date=date(1990, 1, 1),
        gender_male=male,
        area_id=area.id if area else None,
        email_confirmed=True,
        roles=[UserRole(role=r) for r in roles],
    )
    db.add(user)
    await db.flush()
    return user


async def seed_admin(db) -> None:
    await _user(
        db, email=settings.admin_email, password=settings.admin_password, name="HealthHub Admin",
        roles=[Role.ADMIN, Role.PATIENT], area=None, phone=None, national_id=None,
    )
    await db.commit()
    print(f"Admin ready: {settings.admin_email}")


async def seed_demo(db) -> None:
    area = await db.scalar(select(Area).join(Governorate).where(Governorate.key == "Cairo").order_by(Area.key).limit(1))
    spec = await db.scalar(select(Specialty).where(Specialty.name == "Cardiology"))
    doc_user = await _user(
        db, email="doctor@healthhub.local", password="Doctor@12345", name="Ahmed Hassan",
        roles=[Role.PATIENT, Role.DOCTOR], area=area, phone="01012345678", national_id="29001011234567",
    )
    if await db.scalar(select(Doctor).where(Doctor.user_id == doc_user.id)) is None:
        doctor = Doctor(
            user_id=doc_user.id, specialty_id=spec.id, area_id=area.id, college_name="Cairo University",
            summary_career="Consultant cardiologist", address_description="12 Tahrir St.", accepted=True,
            price_session=Decimal("300"), date_of_join=datetime.now(timezone.utc), graduation_year=date(2012, 6, 1),
        )
        db.add(doctor)
        await db.flush()
        for day in ["Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday"]:
            db.add(DoctorSchedule(doctor_id=doctor.id, day_name=day, time_from=time(9), time_to=time(17)))
    await _user(
        db, email="patient@healthhub.local", password="Patient@12345", name="Sara Ali",
        roles=[Role.PATIENT], area=area, phone="01112345678", national_id="29505051234567", male=False,
    )
    ph_user = await _user(
        db, email="pharmacy@healthhub.local", password="Pharmacy@12345", name="Nour Pharmacy Owner",
        roles=[Role.PATIENT, Role.PHARMACY], area=area, phone="01212345678", national_id="28803031234567",
    )
    if await db.scalar(select(Pharmacy).where(Pharmacy.owner_id == ph_user.id)) is None:
        ph = Pharmacy(owner_id=ph_user.id, name="El Nour Pharmacy", area_id=area.id, address_description="5 Nile St.",
                      phone="0223456789", accepted=True)
        db.add(ph)
        await db.flush()
        for drug_id, qty, price in [("DB00316", 120, 25), ("DB01050", 80, 40), ("DB00682", 30, 95)]:
            db.add(PharmacyDrug(pharmacy_id=ph.id, drug_id=drug_id, quantity=qty, price=Decimal(price)))
    h_user = await _user(
        db, email="hospital@healthhub.local", password="Hospital@12345", name="Dar El Shifa Manager",
        roles=[Role.PATIENT, Role.HOSPITAL], area=area, phone="01512345678", national_id="28504041234567",
    )
    if await db.scalar(select(Hospital).where(Hospital.owner_id == h_user.id)) is None:
        h = Hospital(owner_id=h_user.id, name="Dar El Shifa Hospital", area_id=area.id, address_description="1 Ramses St.",
                     phone="0221234567", description="General hospital with 24/7 emergency", accepted=True)
        db.add(h)
        await db.flush()
        doctor = await db.scalar(select(Doctor).where(Doctor.user_id == doc_user.id))
        db.add(HospitalDoctor(hospital_id=h.id, doctor_id=doctor.id, department="Cardiology"))
    await db.commit()
    print("Demo users (password = Role@12345): doctor@, patient@, pharmacy@, hospital@healthhub.local")


def ensure_default_avatar() -> None:
    target = Path(settings.media_dir) / "User" / "default.png"
    if not target.exists():
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy(BASE_DIR / "app" / "static" / "default.png", target)


async def main(demo: bool) -> None:
    ensure_default_avatar()
    async with SessionLocal() as db:
        await seed_reference(db)
        await seed_admin(db)
        if demo:
            await seed_demo(db)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--demo", action="store_true", help="also create a demo doctor and patient")
    asyncio.run(main(parser.parse_args().demo))
