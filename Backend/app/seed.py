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
from datetime import date
from pathlib import Path

from sqlalchemy import select

from app.core.config import BASE_DIR, settings
from app.core.security import hash_password
from app.db.session import SessionLocal
from app.models import Area, Drug, Governorate, Role, Specialty, User, UserRole

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
    from app.demo import seed_demo as rich_demo

    await rich_demo(db)


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
