"""Reference data: governorates, areas, specialties, drugs."""

import uuid

from fastapi import APIRouter, HTTPException, Query
from sqlalchemy import func, select

from app.core.deps import DB, AdminUser
from app.models import Area, Drug, Governorate, Specialty
from app.schemas.v1 import AreaOut, DrugOut, GovernorateOut, SpecialtyIn, SpecialtyOut

router = APIRouter()


@router.get("/governorates", response_model=list[GovernorateOut], tags=["address"])
async def governorates(db: DB):
    return (await db.scalars(select(Governorate).order_by(Governorate.key))).all()


@router.get("/governorates/{governorate_id}/areas", response_model=list[AreaOut], tags=["address"])
async def areas_of(governorate_id: uuid.UUID, db: DB):
    return (await db.scalars(select(Area).where(Area.governorate_id == governorate_id).order_by(Area.key))).all()


@router.get("/specialties", response_model=list[SpecialtyOut], tags=["specialties"])
async def specialties(db: DB):
    return (await db.scalars(select(Specialty).order_by(Specialty.name))).all()


@router.post("/specialties", response_model=SpecialtyOut, status_code=201, tags=["specialties"])
async def add_specialty(body: SpecialtyIn, db: DB, _: AdminUser):
    if await db.scalar(select(Specialty).where(func.lower(Specialty.name) == body.name.strip().lower())):
        raise HTTPException(409, "Specialty already exists")
    row = Specialty(name=body.name.strip())
    db.add(row)
    await db.commit()
    return row


@router.get("/drugs", response_model=list[DrugOut], tags=["drugs"])
async def search_drugs(db: DB, q: str = Query(min_length=2), limit: int = Query(20, le=100)):
    stmt = select(Drug).where(func.lower(Drug.name).contains(q.strip().lower())).order_by(func.length(Drug.name)).limit(limit)
    return (await db.scalars(stmt)).all()


@router.get("/drugs/{drug_id}", response_model=DrugOut, tags=["drugs"])
async def get_drug(drug_id: str, db: DB):
    drug = await db.get(Drug, drug_id)
    if drug is None:
        raise HTTPException(404, "Drug not found")
    return drug
