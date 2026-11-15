"""Old ASP.NET routes, kept byte-compatible so the 2024 Flutter app and React app work unchanged.

Rules this router follows, because the old backend did:
- query string and JSON keys are matched case-insensitively (ASP.NET model binding)
- responses use the old camelCase field names, typos included (paientDateId, dcotorName, ...)
- most business errors come back as HTTP 200 with a message, not as 4xx
New clients should use /api/v1 instead. This file can be deleted once the apps are migrated.
"""

import json
import uuid
from datetime import date, datetime
from decimal import Decimal, InvalidOperation

from fastapi import APIRouter, Request, UploadFile
from fastapi.responses import JSONResponse
from sqlalchemy import func, select

from app.core.config import settings
from app.core.deps import DB, AdminUser, CurrentDoctor, CurrentUser, image_url
from app.models import (
    Appointment,
    Area,
    Doctor,
    Drug,
    Governorate,
    Notification,
    Role,
    Specialty,
    User,
)
from app.services import auth as auth_svc
from app.services import booking, medical
from app.services import doctors as doc_svc
from app.services.common import (
    ServiceError,
    day_name,
    format_ampm,
    parse_day,
    parse_time,
    plus_one_hour,
)

router = APIRouter(include_in_schema=True, tags=["legacy (old ASP.NET routes)"])


# ---------------------------------------------------------------- helpers


def qp(request: Request, *names: str) -> str | None:
    lower = {k.lower(): v for k, v in request.query_params.items()}
    for n in names:
        v = lower.get(n.lower())
        if v not in (None, "", "null", "undefined"):
            return v
    return None


def as_uuid(value) -> uuid.UUID | None:
    try:
        return uuid.UUID(str(value))
    except (ValueError, TypeError):
        return None


def as_bool(value) -> bool:
    return str(value).strip().lower() in ("true", "1", "yes")


def ci(d: dict, *names: str, default=None):
    lower = {str(k).lower(): v for k, v in (d or {}).items()}
    for n in names:
        if n.lower() in lower and lower[n.lower()] is not None:
            return lower[n.lower()]
    return default


async def json_body(request: Request):
    try:
        return await request.json()
    except Exception:  # noqa: BLE001
        return {}


def iso(value) -> str | None:
    if value is None:
        return None
    if isinstance(value, datetime):
        return value.replace(tzinfo=None).isoformat()
    if isinstance(value, date):
        return datetime.combine(value, datetime.min.time()).isoformat()
    return str(value)


def user_image(request: Request, name: str | None) -> str:
    return image_url(request, "User", name or "default.png")


def ouser(*, message: str | None = None, error: bool = False, user: User | None = None, token=None, expires=None) -> dict:
    """The old OUser response shape."""
    return {
        "token": token,
        "userName": user.username if user else None,
        "imgSrc": None,
        "email": user.email if user else None,
        "roles": user.role_names if user else None,
        "message": message,
        "error": error,
        "isLogin": token is not None,
        "gender": user.gender_male if user else False,
        "area": user.area.key if user and user.area else None,
        "gove": user.area.governorate.key if user and user.area else None,
        "exToken": iso(expires) if expires else "0001-01-01T00:00:00",
    }


def legacy_doctor(d: Doctor, request: Request) -> dict:
    u = d.user
    return {
        "id": str(d.id),
        "name": u.name,
        "email": u.email,
        "phone": u.phone or "",
        "drImg": user_image(request, u.image),
        "gender": u.gender_male,
        "dateOfJoin": iso(d.date_of_join) or "0001-01-01T00:00:00",
        "dateOfSendRequest": iso(d.date_of_request),
        "birthdate": iso(u.birth_date),
        "graduationYear": iso(d.graduation_year),
        "collegeName": d.college_name,
        "summaryCareer": d.summary_career,
        "departmentName": d.specialty.name,
        "addressDescrption": d.address_description,
        "accept": d.accepted,
        "rate": d.rating_percent,
        "priceSession": float(d.price_session or 0),
        "area": d.area.key,
        "dates": [{"dayName": s.day_name, "from": format_ampm(s.time_from), "to": format_ampm(s.time_to)} for s in d.schedule],
        "certificates": [{"src": image_url(request, "DoctorCertificates", c.file_name)} for c in d.certificates],
    }


def doctor_list(items: list[Doctor], total: int, request: Request) -> dict:
    return {"doctors": [legacy_doctor(d, request) for d in items], "count": total}


def patient_date(a: Appointment) -> dict:
    d = a.doctor
    return {
        "doctorId": str(d.id),
        "doctorName": d.user.name,
        "doctorSpecialty": d.specialty.name,
        "areaName": d.area.key,
        "governorateName": d.area.governorate.key,
        "paientDateId": str(a.id),
        "from": format_ampm(a.time_from),
        "to": format_ampm(plus_one_hour(a.time_from)),
        "date": a.day.isoformat(),
        "dayName": day_name(a.day),
    }


def repentance(p) -> dict:
    return {
        "drugName": p.drug.name,
        "repeatCount": p.repeat_count,
        "note": p.note,
        "repeat": p.repeat,
        "startdate": p.start_date.isoformat() if p.start_date else None,
        "enddate": p.end_date.isoformat() if p.end_date else None,
    }


def session_with_repentances(s) -> dict:
    u = s.doctor.user
    return {
        "repentances": [repentance(p) for p in s.prescriptions],
        "dcotorName": u.name,
        "doctorPhone": u.phone,
        "doctorEmail": u.email,
        "doctorImg": u.image or "default.png",
        "diseaseName": s.disease_name,
        "doctorId": str(s.doctor_id),
        "date": s.session_date.date().isoformat(),
    }


async def doctor_search(request: Request, db, user: User, *, scope: str, name: str | None = None):
    specialty = as_uuid(qp(request, "specialtie", "specialty"))
    if specialty is None:
        return JSONResponse({"doctors": [], "count": 0}, status_code=400)
    area = as_uuid(qp(request, "area"))
    gove = as_uuid(qp(request, "goveId"))
    # Old defaults: GetDoctorsInArea falls back to the user's area, InGovernorate to the user's governorate
    if scope == "area" and area is None and user.area_id:
        area = user.area_id
    if scope == "gove" and area is None and gove is None and user.area:
        gove = user.area.governorate_id
    sort = "join" if as_bool(qp(request, "joinDate")) else "rate" if as_bool(qp(request, "rate", "reate")) else "none"
    page = int(qp(request, "index") or 0)
    items, total = await doc_svc.search_doctors(
        db, specialty_id=specialty, area_id=area, governorate_id=gove, name=name, sort=sort, page=page
    )
    return doctor_list(items, total, request)


# ================================================================ /Auth


@router.post("/Auth/Login")
async def login(request: Request, db: DB):
    body = await json_body(request)
    login_name, password = ci(body, "userName", "email"), ci(body, "password")
    if not login_name or not password:
        return JSONResponse(ouser(message="Error:Must Enter UserName|Email and Password\n", error=True), status_code=400)
    try:
        user = await auth_svc.authenticate(db, login_name, password)
    except ServiceError as e:
        return ouser(message=e.message, error=True)
    token, expires = auth_svc.issue_token(user)
    data = ouser(user=user, token=token, expires=expires)
    data["imgSrc"] = user_image(request, user.image)
    return data


@router.post("/Auth/Register")
async def register(request: Request, db: DB):
    form = await request.form()
    try:
        data = json.loads(form.get("input") or "")
    except (TypeError, ValueError):
        return JSONResponse(ouser(message="Error in Object Input Or No Data", error=True), status_code=400)
    img = form.get("img") or form.get("Img")
    try:
        birth = parse_day(ci(data, "birday", "birthday", default=""))
        await auth_svc.register_user(
            db,
            name=ci(data, "name", default=""),
            email=ci(data, "email", default=""),
            password=ci(data, "password", default=""),
            phone=ci(data, "phone", default=""),
            birth_date=birth,
            national_id=str(ci(data, "nationalID", default="")),
            gender_male=bool(ci(data, "gender", default=True)),
            area_key=ci(data, "area"),
            image=img if isinstance(img, UploadFile) or hasattr(img, "filename") else None,
        )
    except ServiceError as e:
        return ouser(message=e.message, error=True)
    message = "Check your mail to confirm your email" if settings.require_email_confirmation else "Registered successfully"
    return ouser(message=message)


@router.api_route("/Auth/ForgetPassword", methods=["POST", "PUT"])
async def forget_password(request: Request, db: DB):
    body = await json_body(request)
    email = ci(body if isinstance(body, dict) else {}, "email") or qp(request, "email")
    if email:
        await auth_svc.start_password_reset(db, email)
    return "If this email is registered, a reset code was sent to it"


@router.get("/Auth/GetUser")
async def get_user(request: Request, db: DB, me: CurrentUser):
    email = qp(request, "Email", "data")
    user = await auth_svc.get_user_by_email(db, email) if email else me
    if user is None:
        return None
    if user.id != me.id and not (me.has_role(Role.DOCTOR) or me.has_role(Role.ADMIN) or me.has_role(Role.CUSTOMER_SERVICE)):
        user = me  # patients may only read their own profile
    return {
        "name": user.name,
        "email": user.email,
        "phone": user.phone or "",
        "gove": user.area.governorate.key if user.area else "",
        "area": user.area.key if user.area else "",
        "gender": "Male" if user.gender_male else "Female",
        "img": user.image or "default.png",
        "age": user.age if user.age is not None else -1,
        "birDay": user.birth_date.isoformat() if user.birth_date else None,
    }


@router.put("/Auth/ChangePhoto")
async def change_photo(request: Request, db: DB, user: CurrentUser):
    form = await request.form()
    img = form.get("img") or form.get("Img")
    if not hasattr(img, "filename"):
        return False
    try:
        await auth_svc.change_photo(db, user, img)
    except ServiceError:
        return False
    return True


@router.put("/Auth/ChangePassword")
async def change_password(request: Request, db: DB, user: CurrentUser):
    old, new = qp(request, "OldPassword"), qp(request, "NewPassowrd", "NewPassword")
    if not old or not new:
        return "Must Enter OldPassword And New Password"
    try:
        await auth_svc.change_password(db, user, old, new)
    except ServiceError as e:
        return e.message
    return "Password changed"


async def _legacy_role(request: Request, db, admin: User, add: bool):
    email, role_name = qp(request, "Email"), qp(request, "Role")
    role = next((r for r in Role if role_name and r.value.lower() == role_name.lower()), None)
    user = await auth_svc.get_user_by_email(db, email or "")
    if role is None or user is None:
        return JSONResponse("Select Role", status_code=400)
    await (auth_svc.add_role if add else auth_svc.remove_role)(db, user, role)
    await db.commit()
    return True


@router.put("/Auth/AddRole")
async def add_role(request: Request, db: DB, admin: AdminUser):
    return await _legacy_role(request, db, admin, True)


@router.put("/Auth/RemoveRole")
async def remove_role(request: Request, db: DB, admin: AdminUser):
    return await _legacy_role(request, db, admin, False)


# ================================================================ /Adress


@router.get("/Adress/GetGovernorate")
async def get_governorates(db: DB):
    rows = await db.scalars(select(Governorate).order_by(Governorate.key))
    return [{"id": str(g.id), "key": g.key} for g in rows]


@router.get("/Adress/GetAreas")
async def get_areas(request: Request, db: DB):
    key = qp(request, "GovermentKey", "GovernorateKey")
    if not key:
        return []
    gid = as_uuid(key)
    cond = Governorate.id == gid if gid else func.lower(Governorate.key) == key.lower()
    rows = await db.scalars(select(Area).join(Governorate).where(cond).order_by(Area.key))
    return [{"id": str(a.id), "key": a.key, "governorateId": str(a.governorate_id)} for a in rows]


# ================================================================ /Hospital/Specialties, /Hospital/Drug


@router.get("/Hospital/Specialties")
async def get_specialties(db: DB):
    return [{"id": str(s.id), "name": s.name} for s in await db.scalars(select(Specialty).order_by(Specialty.name))]


@router.get("/Hospital/Drug/SerchByName")
async def search_drug(request: Request, db: DB):
    name = (qp(request, "name") or "").strip().lower()
    if len(name) < 2:
        return []
    rows = await db.scalars(select(Drug).where(func.lower(Drug.name).contains(name)).order_by(func.length(Drug.name)).limit(20))
    return [{"id": d.id, "name": d.name, "smiles": d.smiles} for d in rows]


# ================================================================ /Hospital/Doctor (patient-facing)


@router.get("/Hospital/Doctor/GetDoctorsInGovernorate")
async def doctors_in_governorate(request: Request, db: DB, user: CurrentUser):
    return await doctor_search(request, db, user, scope="gove")


@router.get("/Hospital/Doctor/GetDoctorsInArea")
async def doctors_in_area(request: Request, db: DB, user: CurrentUser):
    return await doctor_search(request, db, user, scope="area")


@router.get("/Hospital/Doctor/SerchDoctorsWithName")
async def doctors_by_name(request: Request, db: DB, user: CurrentUser):
    name = qp(request, "DoctorName")
    if not name or len(name) < 3:
        return JSONResponse({"doctors": [], "count": 0}, status_code=400)
    return await doctor_search(request, db, user, scope="gove", name=name)


@router.get("/Hospital/Doctor/GetDoctor")
async def get_doctor(request: Request, db: DB):
    doctor_id = as_uuid(qp(request, "Id"))
    doctor = await doc_svc.get_doctor(db, doctor_id) if doctor_id else None
    return legacy_doctor(doctor, request) if doctor else None


# ================================================================ /Hospital/Doctor (doctor & admin side, used by the React app)


@router.get("/Hospital/Doctor/CheackRoleDoctor")
async def check_role_doctor(db: DB, user: CurrentUser):
    doctor = await doc_svc.get_doctor_by_user(db, user.id)
    if doctor is None:
        return ouser(message="You need to send a doctor request first", error=True)
    if doctor.rejected:
        return ouser(message="Your Request Has been Rejected,You Can Contact A Customer Service Or Re-Upload The Order", error=True)
    if not doctor.accepted:
        return ouser(message="Your Request Has Not Yet been Reviewed", error=True)
    token, expires = auth_svc.issue_token(user)
    return ouser(message="Accept", user=user, token=token, expires=expires)


@router.post("/Hospital/Doctor/AddDoctor")
async def add_doctor(request: Request, db: DB, user: CurrentUser):
    form = await request.form()
    try:
        data = json.loads(form.get("input") or "")
    except (TypeError, ValueError):
        return JSONResponse({"error": True, "message": "No Data Send"}, status_code=400)
    files = [f for f in form.getlist("Certificates") + form.getlist("certificates") if hasattr(f, "filename")]
    grad = ci(data, "graduationYear")
    try:
        await doc_svc.apply_as_doctor(
            db,
            user,
            specialty_id=as_uuid(ci(data, "specialtieId")),
            area_id=as_uuid(ci(data, "areaClinicId")),
            graduation_year=parse_day(grad) if grad else None,
            college_name=ci(data, "CollegeName", default=""),
            summary_career=ci(data, "SummaryCareer", default=""),
            address_description=ci(data, "AddressDescrption", default=""),
            certificates=files,
        )
    except ServiceError as e:
        return {"error": True, "message": e.message}
    return {"error": False, "message": "Your request was sent and will be reviewed"}


@router.get("/Hospital/Doctor/GetDoctorsNotActive")
async def doctors_not_active(request: Request, db: DB, admin: AdminUser):
    items, total = await doc_svc.pending_requests(db, int(qp(request, "index") or 0))
    return doctor_list(items, total, request)


@router.put("/Hospital/Doctor/ActionDoctor")
async def action_doctor(request: Request, db: DB, admin: AdminUser):
    doctor_id = as_uuid(qp(request, "Id"))
    try:
        await doc_svc.review_request(db, admin, doctor_id, as_bool(qp(request, "action")))
    except ServiceError:
        return False
    return True


@router.get("/Hospital/Doctor/GetDoctorSpecialtie")
async def doctor_specialty(doctor: CurrentDoctor):
    return {"id": str(doctor.specialty.id), "name": doctor.specialty.name}


@router.get("/Hospital/Doctor/DoctorDates")
async def doctor_dates(doctor: CurrentDoctor):
    return [{"dayName": s.day_name, "from": format_ampm(s.time_from), "to": format_ampm(s.time_to)} for s in doctor.schedule]


@router.post("/Hospital/Doctor/AddAppointmentBook")
async def add_appointment_book(request: Request, db: DB, doctor: CurrentDoctor):
    body = await json_body(request)
    days = body if isinstance(body, list) else [body]
    try:
        for d in days:
            await doc_svc.set_schedule_day(db, doctor, ci(d, "dayName", default=""), ci(d, "from", default=""), ci(d, "to", default=""))
    except ServiceError as e:
        return e.message
    return "Save"


@router.put("/Hospital/Doctor/EditAppointmentBook")
async def edit_appointment_book(request: Request, db: DB, doctor: CurrentDoctor):
    d = await json_body(request)
    try:
        await doc_svc.set_schedule_day(
            db, doctor, ci(d, "dayName", default=""), ci(d, "from", default=""), ci(d, "to", default=""),
            old_day=qp(request, "OldDayName"),
        )
    except ServiceError as e:
        return e.message
    return "Save Change"


@router.delete("/Hospital/Doctor/DelteAppointmentBook")
async def delete_appointment_book(request: Request, db: DB, doctor: CurrentDoctor):
    day = qp(request, "OldDayName")
    if not day:
        return "Select Day"
    try:
        await doc_svc.remove_schedule_day(db, doctor, day)
    except ServiceError as e:
        return e.message
    return "Removed"


@router.put("/Hospital/Doctor/ChangePrice")
async def change_price(request: Request, db: DB, doctor: CurrentDoctor):
    try:
        await doc_svc.change_price(db, doctor, Decimal(qp(request, "NewPrice") or "x"))
    except (ServiceError, InvalidOperation):
        return False
    return True


@router.get("/Hospital/Doctor/BookedAppointments")
async def booked_appointments(request: Request, db: DB, doctor: CurrentDoctor):
    out = []
    for a in await booking.doctor_appointments(db, doctor):
        p = a.patient
        out.append(
            {
                "id": str(a.id),
                "name": p.name,
                "email": p.email,
                "phone": p.phone,
                "img": p.image or "default.png",
                "gender": "Male" if p.gender_male else "Female",
                "age": p.age,
                "from": format_ampm(a.time_from),
                "to": format_ampm(plus_one_hour(a.time_from)),
                "date": a.day.isoformat(),
                "dayName": day_name(a.day),
            }
        )
    return out


@router.delete("/Hospital/Doctor/CancelPatientDate")
async def cancel_patient_date(request: Request, db: DB, doctor: CurrentDoctor):
    patient = await auth_svc.get_user_by_email(db, qp(request, "PatientEmail") or "")
    if patient is None:
        return False
    upcoming = [a for a in await booking.doctor_appointments(db, doctor) if a.patient_id == patient.id]
    return await booking.cancel_by_doctor(db, doctor, upcoming[0] if upcoming else None)


@router.get("/Hospital/Doctor/CountOfPatientsWithDoctor")
async def count_patients(db: DB, doctor: CurrentDoctor):
    return (await doc_svc.patient_stats(db, doctor))["total"]


@router.get("/Hospital/Doctor/PatientPercentage")
async def patient_percentage(db: DB, doctor: CurrentDoctor):
    return await doc_svc.patient_stats(db, doctor)


# ---------------------------------------------------------------- /Hospital/Doctor/MedicalSession


@router.get("/Hospital/Doctor/MedicalSession/GetMedicalSessionWithDoctor")
async def sessions_with_doctor(request: Request, db: DB, doctor: CurrentDoctor):
    try:
        rows = await medical.sessions_with_doctor(db, doctor, qp(request, "PaientEmail", "PatientEmail") or "")
    except ServiceError:
        return []
    return [
        {"id": str(s.id), "diseaseName": s.disease_name, "sessionDate": s.session_date.date().isoformat(), "notes": s.notes or "",
         "doctorName": s.doctor.user.name, "repentances": [repentance(p) for p in s.prescriptions]}
        for s in rows
    ]


@router.post("/Hospital/Doctor/MedicalSession")
async def push_medical_session(request: Request, db: DB, doctor: CurrentDoctor):
    body = await json_body(request)
    try:
        items = [
            medical.PrescriptionInput(
                drug_id=str(ci(r, "drugId", default="")),
                note=ci(r, "note"),
                repeat=ci(r, "repeat"),
                repeat_count=int(ci(r, "repeatCount", default=1)),
                start_date=parse_day(ci(r, "startDate")) if ci(r, "startDate") else None,
                end_date=parse_day(ci(r, "endDate")) if ci(r, "endDate") else None,
            )
            for r in ci(body, "repentances", default=[])
        ]
        await medical.create_session(
            db,
            doctor,
            patient_email=ci(body, "patientEmail", default=""),
            disease_name=ci(body, "diseaseName", default=""),
            session_notes=ci(body, "sessionnote"),
            disease_notes=ci(body, "diseasnote"),
            persistent=bool(ci(body, "persistent", default=False)),
            cured=bool(ci(body, "Cured", default=False)),
            prescriptions=items,
        )
    except (ServiceError, ValueError) as e:
        return getattr(e, "message", str(e))
    return "Save"


@router.post("/Hospital/Doctor/MedicalSession/CheackDrugsInteraction")
async def check_interaction(request: Request, db: DB, doctor: CurrentDoctor):
    body = await json_body(request)
    ids = body if isinstance(body, list) else ci(body, "DrugIDs", default=[])
    try:
        result = await medical.check_interactions(db, qp(request, "PaientEmail", "PatientEmail") or "", [str(i) for i in ids])
    except ServiceError as e:
        return {"interactionResult": [e.message], "impact": False}
    lines = [f"{r['drugA']} + {r['drugB']}: {r['description']}" for r in result["results"] if r["interacts"] is not False]
    return {"interactionResult": lines, "impact": result["impact"]}


# ================================================================ /Hospital/Patient


@router.get("/Hospital/Patient/Information/Repentances")
async def repentances(db: DB, user: CurrentUser):
    return [session_with_repentances(s) for s in await medical.patient_sessions(db, user.id)]


@router.get("/Hospital/Patient/Information/Diseases")
async def diseases(db: DB, user: CurrentUser):
    return [
        {"id": str(d.id), "name": d.name, "persistent": d.persistent, "cured": d.cured, "notes": d.notes}
        for d in await medical.patient_diseases(db, user.id)
    ]


@router.get("/Hospital/Patient/information/GetCurrentDrugs")
async def current_drugs(request: Request, db: DB, user: CurrentUser):
    target = user
    email = qp(request, "PatientEmail")
    if email and (user.has_role(Role.DOCTOR) or user.has_role(Role.ADMIN)):
        target = await auth_svc.get_user_by_email(db, email) or user
    return [{"drugId": p.drug_id, **repentance(p)} for p in await medical.current_prescriptions(db, target.id)]


@router.get("/Hospital/Patient/GetDoctorDates")
async def doctor_booked_dates(request: Request, db: DB, user: CurrentUser):
    doctor_id = as_uuid(qp(request, "DoctorId"))
    rows = await booking.booked_slots(db, doctor_id) if doctor_id else []
    return [{"from": format_ampm(a.time_from), "to": format_ampm(plus_one_hour(a.time_from)), "date": a.day.isoformat(), "dayName": day_name(a.day)} for a in rows]


@router.get("/Hospital/Patient/GetPatientDates")
async def patient_dates(db: DB, user: CurrentUser):
    return [patient_date(a) for a in await booking.patient_appointments(db, user)]


@router.post("/Hospital/Patient/PushDateDoctor")
async def push_date(request: Request, db: DB, user: CurrentUser):
    doctor_id = as_uuid(qp(request, "DoctorId"))
    body = await json_body(request)
    if doctor_id is None:
        return "Must Select Doctor"
    try:
        await booking.book(db, user, doctor_id, parse_day(ci(body, "day", default="")), parse_time(ci(body, "from", default="")))
    except ServiceError as e:
        return e.message
    return "Save."


@router.put("/Hospital/Patient/UpdateBookedDate")
async def update_date(request: Request, db: DB, user: CurrentUser):
    appt_id = as_uuid(qp(request, "PaintDateid"))
    body = await json_body(request)
    if appt_id is None:
        return "Must Select Date"
    try:
        await booking.reschedule(db, user, appt_id, parse_day(ci(body, "day", default="")), parse_time(ci(body, "from", default="")))
    except ServiceError as e:
        return e.message
    return "Save Change"


@router.delete("/Hospital/Patient/CancelBookedDate")
async def cancel_date(request: Request, db: DB, user: CurrentUser):
    appt_id = as_uuid(qp(request, "PaintDateid"))
    return await booking.cancel_by_patient(db, user, appt_id) if appt_id else False


@router.post("/Hospital/Patient/Rate/PushRate")
async def push_rate(request: Request, db: DB, user: CurrentUser):
    doctor_id = as_uuid(qp(request, "DoctorID"))
    body = await json_body(request)
    try:
        await doc_svc.rate_doctor(db, user, doctor_id, float(ci(body, "rate", default=-1)), ci(body, "message", default=""))
    except (ServiceError, ValueError, TypeError) as e:
        return JSONResponse(getattr(e, "message", "Invalid rate"), status_code=400)
    return True


# ================================================================ /api/Notification


@router.get("/api/Notification")
async def notifications(db: DB, user: CurrentUser):
    rows = await db.scalars(
        select(Notification).where(Notification.user_id == user.id).order_by(Notification.created_at.desc()).limit(100)
    )
    return [
        {"id": str(n.id), "message": n.message, "dateTime": iso(n.created_at), "notifyHeader": n.type.value, "link": n.link}
        for n in rows
    ]


