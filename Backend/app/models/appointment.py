import uuid
from datetime import date, time
from typing import TYPE_CHECKING

from sqlalchemy import Date, ForeignKey, String, Time, UniqueConstraint, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDMixin

if TYPE_CHECKING:
    from app.models.doctor import Doctor
    from app.models.user import User


WEEKDAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]


class DoctorSchedule(UUIDMixin, Base):
    """One working window per weekday, e.g. Monday 09:00 to 17:00."""

    __tablename__ = "doctor_schedules"
    __table_args__ = (UniqueConstraint("doctor_id", "day_name", name="uq_doctor_day"),)

    doctor_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("doctors.id", ondelete="CASCADE"), index=True)
    day_name: Mapped[str] = mapped_column(String(10), nullable=False)  # Monday..Sunday
    time_from: Mapped[time] = mapped_column(Time, nullable=False)
    time_to: Mapped[time] = mapped_column(Time, nullable=False)

    doctor: Mapped["Doctor"] = relationship(back_populates="schedule")


class Appointment(UUIDMixin, TimestampMixin, Base):
    """A patient booking a one-hour slot with a doctor (old name: PatientDates)."""

    __tablename__ = "appointments"

    patient_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("users.id", ondelete="CASCADE"), index=True)
    doctor_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("doctors.id", ondelete="CASCADE"), index=True)
    day: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    time_from: Mapped[time] = mapped_column(Time, nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="booked")  # booked | cancelled | done

    patient: Mapped["User"] = relationship(back_populates="appointments", lazy="selectin")
    doctor: Mapped["Doctor"] = relationship(back_populates="appointments", lazy="selectin")
