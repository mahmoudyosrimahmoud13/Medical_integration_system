import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, Numeric, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDMixin, utcnow

if TYPE_CHECKING:
    from app.models.address import Area
    from app.models.appointment import Appointment, DoctorSchedule
    from app.models.medical import MedicalSession
    from app.models.user import User


class Specialty(UUIDMixin, Base):
    __tablename__ = "specialties"

    name: Mapped[str] = mapped_column(String(150), unique=True, nullable=False)

    doctors: Mapped[list["Doctor"]] = relationship(back_populates="specialty")


class Doctor(UUIDMixin, TimestampMixin, Base):
    """A doctor profile attached to a user account. `accepted` is set by an admin after review."""

    __tablename__ = "doctors"

    user_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("users.id", ondelete="CASCADE"), unique=True, index=True)
    specialty_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("specialties.id"), index=True)
    area_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("areas.id"), index=True)

    graduation_year: Mapped[date | None] = mapped_column(Date)
    college_name: Mapped[str] = mapped_column(String(200), default="")
    summary_career: Mapped[str] = mapped_column(Text, default="")
    address_description: Mapped[str] = mapped_column(String(300), default="")
    accepted: Mapped[bool] = mapped_column(Boolean, default=False, index=True)
    rejected: Mapped[bool] = mapped_column(Boolean, default=False)
    price_session: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=0)
    date_of_request: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    date_of_join: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    user: Mapped["User"] = relationship(back_populates="doctor_profile", lazy="selectin")
    specialty: Mapped["Specialty"] = relationship(back_populates="doctors", lazy="selectin")
    area: Mapped["Area"] = relationship(back_populates="doctors", lazy="selectin")
    certificates: Mapped[list["DoctorCertificate"]] = relationship(
        back_populates="doctor", cascade="all, delete-orphan", lazy="selectin"
    )
    schedule: Mapped[list["DoctorSchedule"]] = relationship(
        back_populates="doctor", cascade="all, delete-orphan", lazy="selectin"
    )
    reviews: Mapped[list["Review"]] = relationship(back_populates="doctor", cascade="all, delete-orphan", lazy="selectin")
    appointments: Mapped[list["Appointment"]] = relationship(back_populates="doctor")
    medical_sessions: Mapped[list["MedicalSession"]] = relationship(back_populates="doctor")

    @property
    def rating_percent(self) -> float:
        """Old backend formula: sum(rates) / (5 * count) * 100. Returns 0 with no reviews."""
        if not self.reviews:
            return 0.0
        total = sum(float(r.rate) for r in self.reviews)
        return round(total / (5 * len(self.reviews)) * 100, 2)

    @property
    def rating_stars(self) -> float:
        if not self.reviews:
            return 0.0
        return round(sum(float(r.rate) for r in self.reviews) / len(self.reviews), 2)


class DoctorCertificate(UUIDMixin, Base):
    __tablename__ = "doctor_certificates"

    doctor_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("doctors.id", ondelete="CASCADE"), index=True)
    file_name: Mapped[str] = mapped_column(String(255), nullable=False)  # under media/DoctorCertificates

    doctor: Mapped["Doctor"] = relationship(back_populates="certificates")


class Review(UUIDMixin, Base):
    __tablename__ = "reviews"

    doctor_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("doctors.id", ondelete="CASCADE"), index=True)
    patient_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("users.id", ondelete="CASCADE"), index=True)
    rate: Mapped[Decimal] = mapped_column(Numeric(3, 2), nullable=False)  # 0..5
    message: Mapped[str] = mapped_column(Text, default="")
    sent_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    doctor: Mapped["Doctor"] = relationship(back_populates="reviews")
    patient: Mapped["User"] = relationship(lazy="selectin")
