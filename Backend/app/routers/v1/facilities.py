"""Pharmacy and hospital roles, prescription share codes, CT scans and the full medical record."""

import uuid

from fastapi import APIRouter, File, HTTPException, Request, UploadFile

from app.core.deps import DB, AdminUser, CurrentDoctor, CurrentUser, image_url
from app.models import Hospital, Pharmacy
from app.schemas.v1 import (
    AppointmentOut,
    CTScanOut,
    DiseaseOut,
    FacilityApplyIn,
    HospitalDoctorIn,
    HospitalOut,
    HospitalStatusOut,
    MedicalRecordOut,
    MessageOut,
    PharmacyOut,
    PharmacyStatusOut,
    PrescriptionOut,
    ShareCodeOut,
    SharedPrescriptionsOut,
    StockIn,
    StockOut,
    UserOut,
    build_appointment,
    build_hospital,
    build_pharmacy,
    build_session,
    build_stock,
)
from app.services import auth as auth_svc
from app.services import facilities as svc
from app.services import medical

router = APIRouter()


def _ct(request: Request, c) -> CTScanOut:
    return CTScanOut(id=c.id, url=image_url(request, "CTScans", c.file_name), result=c.result, uploaded_at=c.uploaded_at)


# ================================================================ pharmacy (owner side)


@router.post("/pharmacies/apply", response_model=PharmacyStatusOut, status_code=201, tags=["pharmacies"])
async def apply_pharmacy(body: FacilityApplyIn, user: CurrentUser, db: DB):
    ph = await svc.apply_pharmacy(db, user, name=body.name, area_id=body.area_id, address=body.address_description, phone=body.phone)
    return PharmacyStatusOut(status="pending", pharmacy=build_pharmacy(ph))


@router.get("/pharmacies/me", response_model=PharmacyStatusOut, tags=["pharmacies"])
async def my_pharmacy(user: CurrentUser, db: DB):
    ph = await svc.pharmacy_of(db, user)
    if ph is None:
        return PharmacyStatusOut(status="none")
    out = build_pharmacy(ph)
    return PharmacyStatusOut(status=out.status, pharmacy=out, access_token=auth_svc.issue_token(user)[0] if ph.accepted else None)


@router.get("/pharmacies/me/stock", response_model=list[StockOut], tags=["pharmacies"])
async def my_stock(user: CurrentUser, db: DB):
    return [build_stock(r) for r in await svc.stock(db, await svc.accepted_pharmacy(db, user))]


@router.put("/pharmacies/me/stock", response_model=StockOut, tags=["pharmacies"])
async def set_stock(body: StockIn, user: CurrentUser, db: DB):
    row = await svc.set_stock(db, await svc.accepted_pharmacy(db, user), body.drug_id, body.quantity, body.price)
    return build_stock(row)


@router.delete("/pharmacies/me/stock/{drug_id}", response_model=MessageOut, tags=["pharmacies"])
async def remove_stock(drug_id: str, user: CurrentUser, db: DB):
    await svc.remove_stock(db, await svc.accepted_pharmacy(db, user), drug_id)
    return MessageOut(message="Removed")


@router.get("/pharmacies/me/prescriptions", response_model=SharedPrescriptionsOut, tags=["pharmacies"])
async def prescriptions_by_code(code: str, user: CurrentUser, db: DB):
    await svc.accepted_pharmacy(db, user)
    patient, rows = await svc.prescriptions_by_code(db, code)
    return SharedPrescriptionsOut(patient_name=patient.name, prescriptions=[PrescriptionOut.build(p) for p in rows])


# ================================================================ pharmacy (public)


@router.get("/pharmacies", response_model=list[PharmacyOut], tags=["pharmacies"])
async def find_pharmacies(
    db: DB, drug_id: str | None = None, area_id: uuid.UUID | None = None, governorate_id: uuid.UUID | None = None
):
    rows = await svc.find_pharmacies(db, drug_id=drug_id, area_id=area_id, governorate_id=governorate_id)
    return [build_pharmacy(p, item) for p, item in rows]


@router.get("/pharmacies/{pharmacy_id}", response_model=PharmacyOut, tags=["pharmacies"])
async def get_pharmacy(pharmacy_id: uuid.UUID, db: DB):
    ph = await db.get(Pharmacy, pharmacy_id)
    if ph is None or not ph.accepted:
        raise HTTPException(404, "Pharmacy not found")
    return build_pharmacy(ph)


# ================================================================ hospital


@router.post("/hospitals/apply", response_model=HospitalStatusOut, status_code=201, tags=["hospitals"])
async def apply_hospital(body: FacilityApplyIn, user: CurrentUser, db: DB, request: Request):
    h = await svc.apply_hospital(
        db, user, name=body.name, area_id=body.area_id, address=body.address_description, phone=body.phone, description=body.description
    )
    return HospitalStatusOut(status="pending", hospital=build_hospital(h, request))


@router.get("/hospitals/me", response_model=HospitalStatusOut, tags=["hospitals"])
async def my_hospital(user: CurrentUser, db: DB, request: Request):
    h = await svc.hospital_of(db, user)
    if h is None:
        return HospitalStatusOut(status="none")
    out = build_hospital(h, request)
    return HospitalStatusOut(status=out.status, hospital=out, access_token=auth_svc.issue_token(user)[0] if h.accepted else None)


@router.post("/hospitals/me/doctors", response_model=HospitalOut, tags=["hospitals"])
async def add_doctor(body: HospitalDoctorIn, user: CurrentUser, db: DB, request: Request):
    h = await svc.accepted_hospital(db, user)
    await svc.add_hospital_doctor(db, h, body.doctor_email, body.department)
    await db.refresh(h, ["doctors"])
    return build_hospital(h, request)


@router.delete("/hospitals/me/doctors/{doctor_id}", response_model=HospitalOut, tags=["hospitals"])
async def remove_doctor(doctor_id: uuid.UUID, user: CurrentUser, db: DB, request: Request):
    h = await svc.accepted_hospital(db, user)
    await svc.remove_hospital_doctor(db, h, doctor_id)
    await db.refresh(h, ["doctors"])
    return build_hospital(h, request)


@router.get("/hospitals/me/appointments", response_model=list[AppointmentOut], tags=["hospitals"])
async def hospital_appointments(user: CurrentUser, db: DB, request: Request):
    h = await svc.accepted_hospital(db, user)
    return [build_appointment(a, request, with_doctor=True, with_patient=True) for a in await svc.hospital_appointments(db, h)]


@router.get("/hospitals", response_model=list[HospitalOut], tags=["hospitals"])
async def find_hospitals(
    db: DB, request: Request, area_id: uuid.UUID | None = None, governorate_id: uuid.UUID | None = None, name: str | None = None
):
    return [build_hospital(h, request) for h in await svc.find_hospitals(db, area_id=area_id, governorate_id=governorate_id, name=name)]


@router.get("/hospitals/{hospital_id}", response_model=HospitalOut, tags=["hospitals"])
async def get_hospital(hospital_id: uuid.UUID, db: DB, request: Request):
    h = await db.get(Hospital, hospital_id)
    if h is None or not h.accepted:
        raise HTTPException(404, "Hospital not found")
    return build_hospital(h, request)


# ================================================================ admin review


@router.get("/admin/pharmacy-requests", response_model=list[PharmacyOut], tags=["admin"])
async def pharmacy_requests(admin: AdminUser, db: DB):
    return [build_pharmacy(p) for p in await svc.pending(db, Pharmacy)]


@router.post("/admin/pharmacy-requests/{item_id}/{action}", response_model=PharmacyOut, tags=["admin"])
async def review_pharmacy(item_id: uuid.UUID, action: str, admin: AdminUser, db: DB):
    if action not in ("accept", "reject"):
        raise HTTPException(404)
    return build_pharmacy(await svc.review(db, admin, Pharmacy, item_id, action == "accept"))


@router.get("/admin/hospital-requests", response_model=list[HospitalOut], tags=["admin"])
async def hospital_requests(admin: AdminUser, db: DB, request: Request):
    return [build_hospital(h, request) for h in await svc.pending(db, Hospital)]


@router.post("/admin/hospital-requests/{item_id}/{action}", response_model=HospitalOut, tags=["admin"])
async def review_hospital(item_id: uuid.UUID, action: str, admin: AdminUser, db: DB, request: Request):
    if action not in ("accept", "reject"):
        raise HTTPException(404)
    return build_hospital(await svc.review(db, admin, Hospital, item_id, action == "accept"), request)


# ================================================================ medical record extras


@router.post("/medical/share-code", response_model=ShareCodeOut, tags=["medical records"])
async def share_code(user: CurrentUser, db: DB):
    code, expires = await svc.create_share_code(db, user)
    return ShareCodeOut(code=code, expires_at=expires)


@router.post("/medical/ct-scans", response_model=CTScanOut, status_code=201, tags=["medical records"])
async def upload_ct(user: CurrentUser, db: DB, request: Request, file: UploadFile = File(...)):
    return _ct(request, await svc.upload_ct(db, user, file))


@router.get("/medical/ct-scans", response_model=list[CTScanOut], tags=["medical records"])
async def my_ct(user: CurrentUser, db: DB, request: Request):
    return [_ct(request, c) for c in await svc.ct_scans(db, user.id)]


async def _record(db, request, patient) -> MedicalRecordOut:
    return MedicalRecordOut(
        patient=UserOut.build(patient, request),
        diseases=[DiseaseOut.build(d) for d in await medical.patient_diseases(db, patient.id)],
        current_prescriptions=[PrescriptionOut.build(p) for p in await medical.current_prescriptions(db, patient.id)],
        sessions=[build_session(s, request) for s in await medical.patient_sessions(db, patient.id)],
        ct_scans=[_ct(request, c) for c in await svc.ct_scans(db, patient.id)],
    )


@router.get("/medical/record", response_model=MedicalRecordOut, tags=["medical records"])
async def my_record(user: CurrentUser, db: DB, request: Request):
    return await _record(db, request, user)


@router.get("/medical/patients/{patient_email}/record", response_model=MedicalRecordOut, tags=["medical records"])
async def patient_full_record(patient_email: str, doctor: CurrentDoctor, db: DB, request: Request):
    patient = await auth_svc.get_user_by_email(db, patient_email)
    if patient is None:
        raise HTTPException(404, "Patient not found")
    return await _record(db, request, patient)
