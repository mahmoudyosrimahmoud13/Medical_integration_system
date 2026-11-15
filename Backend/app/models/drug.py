from sqlalchemy import Integer, String, Text, UniqueConstraint
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
