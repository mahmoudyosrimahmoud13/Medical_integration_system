import enum
import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import (
    Boolean,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
    Uuid,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, UUIDMixin, utcnow

if TYPE_CHECKING:
    from app.models.address import Area
    from app.models.drug import Drug
    from app.models.user import User


class NotificationType(str, enum.Enum):
    DOCTOR_CHANGED_YOUR_TIME = "Doctor_Change_Your_Time"
    DOCTOR_CANCELLED_YOUR_TIME = "Doctor_Cancel_Your_Time"
    DOCTOR_SELECTED_DATE = "Doctor_Select_Date"
    DOCTOR_ADDED_DAY = "Doctor_Add_New_Day_In_Schedule"
    DOCTOR_REMOVED_DAY = "Doctor_Remove_Day_From_Schedule"
    RATE_DOCTOR = "Rate_Doctor"
    APPOINTMENT_REMINDER = "Alert_Date"
    DOCTOR_REQUEST_RESULT = "Doctor_Result"
    NEW_PRESCRIPTION = "New_Prescription"
    REQUEST_RESULT = "Request_Result"
    NEW_MESSAGE = "New_Message"


class Notification(UUIDMixin, Base):
    __tablename__ = "notifications"

    user_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("users.id", ondelete="CASCADE"), index=True)
    type: Mapped[NotificationType] = mapped_column(Enum(NotificationType, name="notification_type_enum"))
    message: Mapped[str] = mapped_column(Text, nullable=False)
    link: Mapped[str | None] = mapped_column(String(300))
    is_read: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    user: Mapped["User"] = relationship()


class Pharmacy(UUIDMixin, Base):
    __tablename__ = "pharmacies"

    name: Mapped[str] = mapped_column(String(200), nullable=False)
    area_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("areas.id"), index=True)
    address_description: Mapped[str] = mapped_column(String(300), default="")
    phone: Mapped[str | None] = mapped_column(String(20))
    owner_id: Mapped[uuid.UUID | None] = mapped_column(Uuid, ForeignKey("users.id", ondelete="SET NULL"), unique=True)
    accepted: Mapped[bool] = mapped_column(Boolean, default=False, index=True)
    rejected: Mapped[bool] = mapped_column(Boolean, default=False)
    date_of_request: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    area: Mapped["Area"] = relationship(back_populates="pharmacies", lazy="selectin")
    owner: Mapped["User | None"] = relationship(lazy="selectin")
    stock: Mapped[list["PharmacyDrug"]] = relationship(back_populates="pharmacy", cascade="all, delete-orphan")


class PharmacyDrug(Base):
    __tablename__ = "pharmacy_drugs"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    pharmacy_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("pharmacies.id", ondelete="CASCADE"), index=True)
    drug_id: Mapped[str] = mapped_column(String(20), ForeignKey("drugs.id"), index=True)
    quantity: Mapped[int] = mapped_column(Integer, default=0)
    price: Mapped[float] = mapped_column(Numeric(10, 2), default=0)

    pharmacy: Mapped["Pharmacy"] = relationship(back_populates="stock")
    drug: Mapped["Drug"] = relationship(lazy="selectin")


class AdminLog(UUIDMixin, Base):
    __tablename__ = "admin_logs"

    admin_id: Mapped[uuid.UUID | None] = mapped_column(Uuid, ForeignKey("users.id", ondelete="SET NULL"))
    action: Mapped[str] = mapped_column(String(100), nullable=False)
    target: Mapped[str | None] = mapped_column(String(255))
    details: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
