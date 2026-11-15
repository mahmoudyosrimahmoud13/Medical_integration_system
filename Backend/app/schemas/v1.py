"""Request and response models for the clean /api/v1 API, plus builders from ORM objects."""

import re
import uuid
from datetime import date, datetime
from typing import Annotated

from fastapi import Request
from pydantic import AfterValidator, BaseModel, ConfigDict, Field

from app.core.deps import image_url
from app.ml.client import describe  # noqa: F401  (re-exported for routers)
from app.models import (
    Appointment,
    Disease,
    Doctor,
    MedicalSession,
    Notification,
    Prescription,
    Review,
    User,
)
from app.services.common import day_name, format_ampm, plus_one_hour

_EMAIL = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def _check_email(v: str) -> str:
    v = v.strip().lower()
    if not _EMAIL.match(v):
        raise ValueError("Must Enter Email (***@example.com)")
    return v


# Simple email check. Pydantic's EmailStr rejects reserved domains like .local that we use for demo accounts.
EmailStr = Annotated[str, AfterValidator(_check_email)]


class Out(BaseModel):
    model_config = ConfigDict(from_attributes=True)


class MessageOut(Out):
    message: str


# ---------------------------------------------------------------- address / specialties


class GovernorateOut(Out):
    id: uuid.UUID
    key: str
    name_ar: str | None = None


class AreaOut(Out):
    id: uuid.UUID
    key: str
    name_ar: str | None = None
    governorate_id: uuid.UUID


class SpecialtyOut(Out):
    id: uuid.UUID
    name: str


class SpecialtyIn(BaseModel):
    name: str = Field(min_length=2, max_length=150)


# ---------------------------------------------------------------- auth / users


class RegisterIn(BaseModel):
    name: str = Field(min_length=3, max_length=200)
    email: EmailStr
    password: str
    phone: str
    birth_date: date
    national_id: str
    gender: str = Field(pattern="^(male|female)$")
    area_id: uuid.UUID


class LoginIn(BaseModel):
    login: str = Field(description="Email or username")
    password: str


class ForgotPasswordIn(BaseModel):
    email: EmailStr


class ResetPasswordIn(BaseModel):
    token: str
    new_password: str


class ChangePasswordIn(BaseModel):
    old_password: str
    new_password: str


class UserOut(Out):
    id: uuid.UUID
    name: str
    email: str
    username: str
    phone: str | None
    gender: str
    birth_date: date | None
    age: int | None
    image_url: str | None
    roles: list[str]
    area: AreaOut | None
    governorate: GovernorateOut | None
    email_confirmed: bool

    @classmethod
    def build(cls, u: User, request: Request) -> "UserOut":
        return cls(
            id=u.id,
            name=u.name,
            email=u.email,
            username=u.username,
            phone=u.phone,
            gender="male" if u.gender_male else "female",
            birth_date=u.birth_date,
            age=u.age,
            image_url=image_url(request, "User", u.image),
            roles=u.role_names,
            area=AreaOut.model_validate(u.area) if u.area else None,
            governorate=GovernorateOut.model_validate(u.area.governorate) if u.area else None,
            email_confirmed=u.email_confirmed,
        )


class TokenOut(Out):
    access_token: str
    token_type: str = "bearer"
    expires_at: datetime
    user: UserOut


# ---------------------------------------------------------------- doctors


class ScheduleDayIn(BaseModel):
    day_name: str = Field(examples=["Monday"])
    time_from: str = Field(examples=["09:00 AM"])
    time_to: str = Field(examples=["05:00 PM"])


class ScheduleDayOut(Out):
    day_name: str
    time_from: str
    time_to: str


class PriceIn(BaseModel):
    price: float = Field(ge=0)


class DoctorSummaryOut(Out):
    id: uuid.UUID
    name: str
    image_url: str | None
    phone: str | None
    specialty: SpecialtyOut
    area: AreaOut
    governorate: GovernorateOut
    address_description: str
    price_session: float
    rating_stars: float
    rating_percent: float
    review_count: int


class DoctorOut(DoctorSummaryOut):
    email: str
    gender: str
    college_name: str
    graduation_year: date | None
    summary_career: str
    date_of_join: datetime | None
    schedule: list[ScheduleDayOut]
    certificates: list[str]


class DoctorRequestOut(DoctorOut):
    accepted: bool
    rejected: bool
    date_of_request: datetime


def _doctor_fields(d: Doctor, request: Request) -> dict:
    u = d.user
    return dict(
        id=d.id,
        name=u.name,
        image_url=image_url(request, "User", u.image),
        phone=u.phone,
        specialty=SpecialtyOut.model_validate(d.specialty),
        area=AreaOut.model_validate(d.area),
        governorate=GovernorateOut.model_validate(d.area.governorate),
        address_description=d.address_description,
        price_session=float(d.price_session or 0),
        rating_stars=d.rating_stars,
        rating_percent=d.rating_percent,
        review_count=len(d.reviews),
    )


def build_doctor_summary(d: Doctor, request: Request) -> DoctorSummaryOut:
    return DoctorSummaryOut(**_doctor_fields(d, request))


def _doctor_detail_fields(d: Doctor, request: Request) -> dict:
    return dict(
        **_doctor_fields(d, request),
        email=d.user.email,
        gender="male" if d.user.gender_male else "female",
        college_name=d.college_name,
        graduation_year=d.graduation_year,
        summary_career=d.summary_career,
        date_of_join=d.date_of_join,
        schedule=[build_schedule_day(s) for s in sorted(d.schedule, key=lambda s: _day_index(s.day_name))],
        certificates=[image_url(request, "DoctorCertificates", c.file_name) for c in d.certificates],
    )


def build_doctor(d: Doctor, request: Request) -> DoctorOut:
    return DoctorOut(**_doctor_detail_fields(d, request))


def build_doctor_request(d: Doctor, request: Request) -> DoctorRequestOut:
    return DoctorRequestOut(
        **_doctor_detail_fields(d, request), accepted=d.accepted, rejected=d.rejected, date_of_request=d.date_of_request
    )


def _day_index(name: str) -> int:
    from app.services.common import WEEKDAYS

    return WEEKDAYS.index(name) if name in WEEKDAYS else 99


def build_schedule_day(s) -> ScheduleDayOut:
    return ScheduleDayOut(day_name=s.day_name, time_from=format_ampm(s.time_from), time_to=format_ampm(s.time_to))


class DoctorPage(Out):
    items: list[DoctorSummaryOut]
    total: int
    page: int
    page_size: int


class DoctorRequestPage(Out):
    items: list[DoctorRequestOut]
    total: int
    page: int


class DoctorStatusOut(Out):
    status: str  # none | pending | rejected | accepted
    doctor: DoctorRequestOut | None = None
    access_token: str | None = Field(None, description="Fresh token with the Doctor role, when accepted")


class ReviewIn(BaseModel):
    rate: float = Field(ge=0, le=5)
    message: str = ""


class ReviewOut(Out):
    id: uuid.UUID
    rate: float
    message: str
    sent_at: datetime
    patient_name: str

    @classmethod
    def build(cls, r: Review) -> "ReviewOut":
        return cls(id=r.id, rate=float(r.rate), message=r.message, sent_at=r.sent_at, patient_name=r.patient.name)


class DoctorStatsOut(Out):
    total: int
    male: int
    female: int
    male_percentage: float
    female_percentage: float
    upcoming_appointments: int


# ---------------------------------------------------------------- appointments


class BookIn(BaseModel):
    doctor_id: uuid.UUID
    day: date
    time_from: str = Field(examples=["10:00 AM"])


class RescheduleIn(BaseModel):
    day: date
    time_from: str


class PersonOut(Out):
    id: uuid.UUID
    name: str
    image_url: str | None


class AppointmentDoctorOut(PersonOut):
    specialty: str
    area: str
    governorate: str
    phone: str | None


class AppointmentPatientOut(PersonOut):
    email: str
    phone: str | None
    gender: str
    age: int | None


class AppointmentOut(Out):
    id: uuid.UUID
    day: date
    day_name: str
    time_from: str
    time_to: str
    status: str
    doctor: AppointmentDoctorOut | None = None
    patient: AppointmentPatientOut | None = None


def build_appointment(a: Appointment, request: Request, *, with_doctor=True, with_patient=False) -> AppointmentOut:
    out = AppointmentOut(
        id=a.id,
        day=a.day,
        day_name=day_name(a.day),
        time_from=format_ampm(a.time_from),
        time_to=format_ampm(plus_one_hour(a.time_from)),
        status=a.status,
    )
    if with_doctor:
        d = a.doctor
        out.doctor = AppointmentDoctorOut(
            id=d.id,
            name=d.user.name,
            image_url=image_url(request, "User", d.user.image),
            specialty=d.specialty.name,
            area=d.area.key,
            governorate=d.area.governorate.key,
            phone=d.user.phone,
        )
    if with_patient:
        p = a.patient
        out.patient = AppointmentPatientOut(
            id=p.id,
            name=p.name,
            image_url=image_url(request, "User", p.image),
            email=p.email,
            phone=p.phone,
            gender="male" if p.gender_male else "female",
            age=p.age,
        )
    return out


class BookedSlotOut(Out):
    day: date
    day_name: str
    time_from: str
    time_to: str


# ---------------------------------------------------------------- medical records


class PrescriptionIn(BaseModel):
    drug_id: str
    note: str | None = None
    repeat: str | None = None
    repeat_count: int = Field(1, ge=1)
    start_date: date | None = None
    end_date: date | None = None


class SessionIn(BaseModel):
    patient_email: EmailStr
    disease_name: str = Field(min_length=2)
    session_notes: str | None = None
    disease_notes: str | None = None
    persistent: bool = False
    cured: bool = False
    prescriptions: list[PrescriptionIn] = []


class PrescriptionOut(Out):
    id: uuid.UUID
    drug_id: str
    drug_name: str
    note: str | None
    repeat: str | None
    repeat_count: int
    start_date: date | None
    end_date: date | None

    @classmethod
    def build(cls, p: Prescription) -> "PrescriptionOut":
        return cls(
            id=p.id,
            drug_id=p.drug_id,
            drug_name=p.drug.name,
            note=p.note,
            repeat=p.repeat,
            repeat_count=p.repeat_count,
            start_date=p.start_date,
            end_date=p.end_date,
        )


class SessionDoctorOut(PersonOut):
    email: str
    phone: str | None
    specialty: str


class SessionOut(Out):
    id: uuid.UUID
    session_date: datetime
    disease_name: str
    notes: str | None
    doctor: SessionDoctorOut
    patient_name: str
    prescriptions: list[PrescriptionOut]


def build_session(s: MedicalSession, request: Request) -> SessionOut:
    d = s.doctor
    return SessionOut(
        id=s.id,
        session_date=s.session_date,
        disease_name=s.disease_name,
        notes=s.notes,
        doctor=SessionDoctorOut(
            id=d.id,
            name=d.user.name,
            image_url=image_url(request, "User", d.user.image),
            email=d.user.email,
            phone=d.user.phone,
            specialty=d.specialty.name,
        ),
        patient_name=s.patient.name,
        prescriptions=[PrescriptionOut.build(p) for p in s.prescriptions],
    )


class DiseaseOut(Out):
    id: uuid.UUID
    name: str
    persistent: bool
    cured: bool
    notes: str | None
    responsible_doctor: str | None

    @classmethod
    def build(cls, d: Disease) -> "DiseaseOut":
        return cls(
            id=d.id,
            name=d.name,
            persistent=d.persistent,
            cured=d.cured,
            notes=d.notes,
            responsible_doctor=d.responsible_doctor.user.name if d.responsible_doctor else None,
        )


class InteractionCheckIn(BaseModel):
    patient_email: EmailStr
    drug_ids: list[str] = Field(min_length=1)


class InteractionPairOut(Out):
    drugA: str
    drugB: str
    interacts: bool | None
    interactionType: int | None
    description: str


class InteractionCheckOut(Out):
    available: bool
    impact: bool
    results: list[InteractionPairOut]


# ---------------------------------------------------------------- drugs, notifications, admin


class DrugOut(Out):
    id: str
    name: str


class NotificationOut(Out):
    id: uuid.UUID
    type: str
    message: str
    link: str | None
    is_read: bool
    created_at: datetime

    @classmethod
    def build(cls, n: Notification) -> "NotificationOut":
        return cls(id=n.id, type=n.type.value, message=n.message, link=n.link, is_read=n.is_read, created_at=n.created_at)


class RoleChangeIn(BaseModel):
    email: EmailStr
    role: str = Field(examples=["Admin", "CustomerService", "Doctor", "Pharmacy", "Hospital"])


# ---------------------------------------------------------------- pharmacies and hospitals


class FacilityApplyIn(BaseModel):
    name: str = Field(min_length=3, max_length=200)
    area_id: uuid.UUID
    address_description: str = ""
    phone: str | None = None
    description: str = ""  # hospitals only


class StockIn(BaseModel):
    drug_id: str
    quantity: int = Field(ge=0)
    price: float = Field(ge=0)


class StockOut(Out):
    drug_id: str
    drug_name: str
    quantity: int
    price: float


def build_stock(row) -> StockOut:
    return StockOut(drug_id=row.drug_id, drug_name=row.drug.name, quantity=row.quantity, price=float(row.price or 0))


class PharmacyOut(Out):
    id: uuid.UUID
    name: str
    area: AreaOut
    governorate: GovernorateOut
    address_description: str
    phone: str | None
    status: str
    item: StockOut | None = None  # filled when searching for a drug


def _status(x) -> str:
    return "accepted" if x.accepted else "rejected" if x.rejected else "pending"


def build_pharmacy(p, item=None) -> PharmacyOut:
    return PharmacyOut(
        id=p.id,
        name=p.name,
        area=AreaOut.model_validate(p.area),
        governorate=GovernorateOut.model_validate(p.area.governorate),
        address_description=p.address_description,
        phone=p.phone,
        status=_status(p),
        item=build_stock(item) if item else None,
    )


class FacilityStatusOut(Out):
    status: str  # none | pending | rejected | accepted
    access_token: str | None = None


class PharmacyStatusOut(FacilityStatusOut):
    pharmacy: PharmacyOut | None = None


class ShareCodeOut(Out):
    code: str
    expires_at: datetime


class SharedPrescriptionsOut(Out):
    patient_name: str
    prescriptions: list[PrescriptionOut]


class HospitalDoctorOut(Out):
    doctor: DoctorSummaryOut
    department: str


class HospitalOut(Out):
    id: uuid.UUID
    name: str
    description: str
    area: AreaOut
    governorate: GovernorateOut
    address_description: str
    phone: str | None
    status: str
    doctors: list[HospitalDoctorOut]


def build_hospital(h, request: Request) -> HospitalOut:
    return HospitalOut(
        id=h.id,
        name=h.name,
        description=h.description,
        area=AreaOut.model_validate(h.area),
        governorate=GovernorateOut.model_validate(h.area.governorate),
        address_description=h.address_description,
        phone=h.phone,
        status=_status(h),
        doctors=[HospitalDoctorOut(doctor=build_doctor_summary(link.doctor, request), department=link.department) for link in h.doctors],
    )


class HospitalStatusOut(FacilityStatusOut):
    hospital: HospitalOut | None = None


class HospitalDoctorIn(BaseModel):
    doctor_email: EmailStr
    department: str = ""


class CTScanOut(Out):
    id: uuid.UUID
    url: str
    result: str | None
    uploaded_at: datetime


class MedicalRecordOut(Out):
    patient: UserOut
    diseases: list[DiseaseOut]
    current_prescriptions: list[PrescriptionOut]
    sessions: list[SessionOut]
    ct_scans: list[CTScanOut]
