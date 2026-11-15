import uuid
from typing import TYPE_CHECKING

from sqlalchemy import ForeignKey, String, UniqueConstraint, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, UUIDMixin

if TYPE_CHECKING:
    from app.models.doctor import Doctor
    from app.models.misc import Pharmacy
    from app.models.user import User


class Governorate(UUIDMixin, Base):
    __tablename__ = "governorates"

    # "key" is the English name; kept as the public identifier for compatibility with the old API
    key: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    name_ar: Mapped[str | None] = mapped_column(String(100))

    areas: Mapped[list["Area"]] = relationship(back_populates="governorate", cascade="all, delete-orphan")


class Area(UUIDMixin, Base):
    __tablename__ = "areas"
    __table_args__ = (UniqueConstraint("governorate_id", "key", name="uq_area_key_per_governorate"),)

    key: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    name_ar: Mapped[str | None] = mapped_column(String(100))
    governorate_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("governorates.id", ondelete="CASCADE"), index=True)

    governorate: Mapped["Governorate"] = relationship(back_populates="areas", lazy="selectin")
    users: Mapped[list["User"]] = relationship(back_populates="area")
    doctors: Mapped[list["Doctor"]] = relationship(back_populates="area")
    pharmacies: Mapped[list["Pharmacy"]] = relationship(back_populates="area")
