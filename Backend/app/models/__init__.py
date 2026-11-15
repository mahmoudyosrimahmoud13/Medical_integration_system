"""Import every model here so SQLAlchemy and Alembic see the whole schema."""

from app.models.address import Area, Governorate
from app.models.appointment import Appointment, DoctorSchedule
from app.models.doctor import Doctor, DoctorCertificate, Review, Specialty
from app.models.drug import Drug, DrugInteraction
from app.models.facility import Hospital, HospitalDoctor
from app.models.medical import CTScan, Disease, MedicalSession, Prescription
from app.models.misc import (
    AdminLog,
    Message,
    Notification,
    NotificationType,
    Pharmacy,
    PharmacyDrug,
)
from app.models.user import PasswordResetToken, Role, User, UserRole

__all__ = [
    "Area",
    "Governorate",
    "Appointment",
    "DoctorSchedule",
    "Doctor",
    "DoctorCertificate",
    "Review",
    "Specialty",
    "Drug",
    "DrugInteraction",
    "Hospital",
    "HospitalDoctor",
    "CTScan",
    "Disease",
    "MedicalSession",
    "Prescription",
    "AdminLog",
    "Message",
    "Notification",
    "NotificationType",
    "Pharmacy",
    "PharmacyDrug",
    "PasswordResetToken",
    "Role",
    "User",
    "UserRole",
]
