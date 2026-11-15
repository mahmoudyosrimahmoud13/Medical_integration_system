"""Hospitals. Pharmacies live in misc.py next to their stock table."""

import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import (
    Boolean,
    DateTime,
    ForeignKey,
    String,
    Text,
    UniqueConstraint,
    Uuid,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, UUIDMixin, utcnow

if TYPE_CHECKING:
    from app.models.address import Area
    from app.models.doctor import Doctor
    from app.models.user import User


class Hospital(UUIDMixin, Base):
    __tablename__ = "hospitals"

    name: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str] = mapped_column(Text, default="")
    area_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("areas.id"), index=True)
    address_description: Mapped[str] = mapped_column(String(300), default="")
    phone: Mapped[str | None] = mapped_column(String(20))
    owner_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("users.id", ondelete="CASCADE"), unique=True, index=True)
    accepted: Mapped[bool] = mapped_column(Boolean, default=False, index=True)
    rejected: Mapped[bool] = mapped_column(Boolean, default=False)
    date_of_request: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    area: Mapped["Area"] = relationship(lazy="selectin")
    owner: Mapped["User"] = relationship(lazy="selectin")
    doctors: Mapped[list["HospitalDoctor"]] = relationship(back_populates="hospital", cascade="all, delete-orphan", lazy="selectin")


class HospitalDoctor(Base):
    """A doctor working at a hospital, in a department."""

    __tablename__ = "hospital_doctors"
    __table_args__ = (UniqueConstraint("hospital_id", "doctor_id", name="uq_hospital_doctor"),)

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    hospital_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("hospitals.id", ondelete="CASCADE"), index=True)
    doctor_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("doctors.id", ondelete="CASCADE"), index=True)
    department: Mapped[str] = mapped_column(String(150), default="")

    hospital: Mapped["Hospital"] = relationship(back_populates="doctors")
    doctor: Mapped["Doctor"] = relationship(lazy="selectin")
