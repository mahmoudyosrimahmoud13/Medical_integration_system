import uuid
from datetime import date, datetime
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, Integer, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDMixin, utcnow

if TYPE_CHECKING:
    from app.models.doctor import Doctor
    from app.models.drug import Drug
    from app.models.user import User


class Disease(UUIDMixin, Base):
    __tablename__ = "diseases"

    patient_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("users.id", ondelete="CASCADE"), index=True)
    responsible_doctor_id: Mapped[uuid.UUID | None] = mapped_column(Uuid, ForeignKey("doctors.id", ondelete="SET NULL"))
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    persistent: Mapped[bool] = mapped_column(Boolean, default=False)  # chronic
    cured: Mapped[bool] = mapped_column(Boolean, default=False)
    notes: Mapped[str | None] = mapped_column(Text)

    patient: Mapped["User"] = relationship(back_populates="diseases")
    responsible_doctor: Mapped["Doctor | None"] = relationship(lazy="selectin")


class MedicalSession(UUIDMixin, TimestampMixin, Base):
    """A visit: doctor + patient + diagnosis + the prescriptions written during it."""

    __tablename__ = "medical_sessions"

    doctor_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("doctors.id", ondelete="CASCADE"), index=True)
    patient_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("users.id", ondelete="CASCADE"), index=True)
    session_date: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    disease_name: Mapped[str] = mapped_column(String(200), nullable=False)
    notes: Mapped[str | None] = mapped_column(Text)

    doctor: Mapped["Doctor"] = relationship(back_populates="medical_sessions", lazy="selectin")
    patient: Mapped["User"] = relationship(back_populates="medical_sessions", lazy="selectin")
    prescriptions: Mapped[list["Prescription"]] = relationship(
        back_populates="session", cascade="all, delete-orphan", lazy="selectin"
    )


class Prescription(UUIDMixin, Base):
    """One drug line in a medical session (old name: Repentance)."""

    __tablename__ = "prescriptions"

    session_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("medical_sessions.id", ondelete="CASCADE"), index=True)
    drug_id: Mapped[str] = mapped_column(String(20), ForeignKey("drugs.id"), index=True)
    note: Mapped[str | None] = mapped_column(Text)
    repeat: Mapped[str | None] = mapped_column(String(50))  # e.g. "daily", "every 8 hours"
    repeat_count: Mapped[int] = mapped_column(Integer, default=1)
    start_date: Mapped[date | None] = mapped_column(Date)
    end_date: Mapped[date | None] = mapped_column(Date)

    session: Mapped["MedicalSession"] = relationship(back_populates="prescriptions")
    drug: Mapped["Drug"] = relationship(lazy="selectin")


class CTScan(UUIDMixin, Base):
    __tablename__ = "ct_scans"

    patient_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("users.id", ondelete="CASCADE"), index=True)
    file_name: Mapped[str] = mapped_column(String(255), nullable=False)
    result: Mapped[str | None] = mapped_column(Text)  # ML prediction, if any
    uploaded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    patient: Mapped["User"] = relationship(lazy="selectin")
