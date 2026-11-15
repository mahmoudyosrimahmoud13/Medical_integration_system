from sqlalchemy import Boolean, Integer, Numeric, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Drug(Base):
    """Drug catalogue. Id is the DrugBank id (e.g. DB00855) from the seed CSV."""

    __tablename__ = "drugs"

    id: Mapped[str] = mapped_column(String(20), primary_key=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    smiles: Mapped[str] = mapped_column(Text, nullable=False)


class DrugInteraction(Base):
    """Cached result of the ML interaction model for a pair of drugs (sorted pair)."""

    __tablename__ = "drug_interactions"
    __table_args__ = (UniqueConstraint("drug_a_id", "drug_b_id", name="uq_drug_pair"),)

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    drug_a_id: Mapped[str] = mapped_column(String(20), index=True)
    drug_b_id: Mapped[str] = mapped_column(String(20), index=True)
    interacts: Mapped[bool] = mapped_column(nullable=False)
    interaction_type: Mapped[int | None] = mapped_column(Integer)  # index from the model, -1 = none
    reason: Mapped[str | None] = mapped_column(Text)


class Product(Base):
    """A branded product on the Egyptian market, linked to its active ingredient in `drugs`."""

    __tablename__ = "products"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    brand: Mapped[str] = mapped_column(String(120), nullable=False, index=True)
    drug_id: Mapped[str] = mapped_column(String(20), index=True)  # FK to drugs.id (active ingredient)
    strength: Mapped[str] = mapped_column(String(80), default="")
    form: Mapped[str] = mapped_column(String(40), default="")  # tablet, capsule, syrup, inhaler...
    pack: Mapped[str] = mapped_column(String(60), default="")
    manufacturer: Mapped[str] = mapped_column(String(120), default="")
    category: Mapped[str] = mapped_column(String(60), default="", index=True)
    price_egp: Mapped[float] = mapped_column(Numeric(10, 2), default=0)
    prescription_only: Mapped[bool] = mapped_column(Boolean, default=True)

    @property
    def display_name(self) -> str:
        return f"{self.brand} {self.strength} {self.form}".strip()
