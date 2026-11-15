import enum
import uuid
from datetime import date, datetime
from typing import TYPE_CHECKING

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    Enum,
    ForeignKey,
    String,
    UniqueConstraint,
    Uuid,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDMixin

if TYPE_CHECKING:
    from app.models.address import Area
    from app.models.appointment import Appointment
    from app.models.doctor import Doctor
    from app.models.medical import Disease, MedicalSession


class Role(str, enum.Enum):
    PATIENT = "Patient"
    DOCTOR = "Doctor"
    ADMIN = "Admin"
    CUSTOMER_SERVICE = "CustomerService"
    PHARMACY = "Pharmacy"  # reserved for the pharmacy phase
    HOSPITAL = "Hospital"  # reserved for the hospital phase


class User(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "users"

    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    username: Mapped[str] = mapped_column(String(100), unique=True, index=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    phone: Mapped[str | None] = mapped_column(String(20))
    national_id: Mapped[str | None] = mapped_column(String(14), unique=True)
    birth_date: Mapped[date | None] = mapped_column(Date)
    gender_male: Mapped[bool] = mapped_column(Boolean, default=True)  # old API: gender=true means Male
    image: Mapped[str | None] = mapped_column(String(255))  # file name under media/User
    email_confirmed: Mapped[bool] = mapped_column(Boolean, default=False)
    is_blocked: Mapped[bool] = mapped_column(Boolean, default=False)

    area_id: Mapped[uuid.UUID | None] = mapped_column(Uuid, ForeignKey("areas.id", ondelete="SET NULL"))
    area: Mapped["Area | None"] = relationship(back_populates="users", lazy="selectin")

    roles: Mapped[list["UserRole"]] = relationship(back_populates="user", cascade="all, delete-orphan", lazy="selectin")
    doctor_profile: Mapped["Doctor | None"] = relationship(back_populates="user", uselist=False)
    appointments: Mapped[list["Appointment"]] = relationship(back_populates="patient")
    diseases: Mapped[list["Disease"]] = relationship(back_populates="patient")
    medical_sessions: Mapped[list["MedicalSession"]] = relationship(back_populates="patient")

    @property
    def role_names(self) -> list[str]:
        return [r.role.value for r in self.roles]

    def has_role(self, role: Role) -> bool:
        return any(r.role == role for r in self.roles)

    @property
    def age(self) -> int | None:
        if not self.birth_date:
            return None
        today = date.today()
        return today.year - self.birth_date.year - ((today.month, today.day) < (self.birth_date.month, self.birth_date.day))


class UserRole(Base):
    __tablename__ = "user_roles"
    __table_args__ = (UniqueConstraint("user_id", "role", name="uq_user_role"),)

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("users.id", ondelete="CASCADE"), index=True)
    role: Mapped[Role] = mapped_column(Enum(Role, name="role_enum"), nullable=False)

    user: Mapped["User"] = relationship(back_populates="roles")


class PasswordResetToken(Base):
    __tablename__ = "password_reset_tokens"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("users.id", ondelete="CASCADE"), index=True)
    token: Mapped[str] = mapped_column(String(128), unique=True, index=True)
    purpose: Mapped[str] = mapped_column(String(32), default="reset")  # "reset" or "confirm"
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    used: Mapped[bool] = mapped_column(Boolean, default=False)
