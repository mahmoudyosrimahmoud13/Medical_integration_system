"""Import every model here so SQLAlchemy and Alembic see the whole schema."""

from app.models.address import Area, Governorate
from app.models.appointment import Appointment, DoctorSchedule
from app.models.chat import ChatMessage, Conversation
from app.models.doctor import Doctor, DoctorCertificate, Review, Specialty
from app.models.drug import Drug, DrugInteraction, Product
from app.models.facility import Hospital, HospitalDoctor
from app.models.medical import CTScan, Disease, MedicalSession, Prescription
from app.models.misc import (
    AdminLog,
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
    "Product",
    "Hospital",
    "HospitalDoctor",
    "CTScan",
    "Disease",
    "MedicalSession",
    "Prescription",
    "AdminLog",
    "ChatMessage",
    "Conversation",
    "Notification",
    "NotificationType",
    "Pharmacy",
    "PharmacyDrug",
    "PasswordResetToken",
    "Role",
    "User",
    "UserRole",
]
