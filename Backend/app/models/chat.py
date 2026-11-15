"""Conversations between two users. Who may start one is decided in services/chat.py."""

import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, ForeignKey, Index, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, UUIDMixin, utcnow

if TYPE_CHECKING:
    from app.models.user import User


class Conversation(UUIDMixin, Base):
    __tablename__ = "conversations"
    __table_args__ = (Index("ix_conversation_pair", "user_a_id", "user_b_id", unique=True),)

    # user_a_id < user_b_id (as strings) so each pair has exactly one row
    user_a_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("users.id", ondelete="CASCADE"), index=True)
    user_b_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("users.id", ondelete="CASCADE"), index=True)
    subject: Mapped[str] = mapped_column(String(120), default="")  # e.g. "Appointment on 2026-01-05"
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    last_message_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)

    user_a: Mapped["User"] = relationship(foreign_keys=[user_a_id], lazy="selectin")
    user_b: Mapped["User"] = relationship(foreign_keys=[user_b_id], lazy="selectin")
    messages: Mapped[list["ChatMessage"]] = relationship(back_populates="conversation", cascade="all, delete-orphan")

    def other(self, user_id: uuid.UUID) -> "User":
        return self.user_b if self.user_a_id == user_id else self.user_a


class ChatMessage(UUIDMixin, Base):
    __tablename__ = "chat_messages"

    conversation_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("conversations.id", ondelete="CASCADE"), index=True)
    sender_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("users.id", ondelete="CASCADE"), index=True)
    text: Mapped[str] = mapped_column(Text, nullable=False)
    sent_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)
    read_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    conversation: Mapped["Conversation"] = relationship(back_populates="messages")
    sender: Mapped["User"] = relationship(lazy="selectin")
