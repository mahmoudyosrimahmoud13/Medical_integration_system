"""Messaging between roles.

Who can talk to whom (no cold messaging; every link comes from a real relationship in the system):

  patient  <-> doctor     the patient has, or had, an appointment with the doctor
  patient  <-> pharmacy   the patient shared a prescription code with that pharmacy, or
                          the pharmacy is accepted (patients may ask any pharmacy about stock)
  patient  <-> hospital   the hospital is accepted (ask about departments, visits)
  doctor   <-> hospital   the doctor works at the hospital
  doctor   <-> doctor     both work at the same hospital (referrals)
  admin    <-> anyone     support
  anyone   -> admin       support

Once a conversation exists both sides can keep writing in it.
"""

import uuid
from datetime import datetime, timezone

from sqlalchemy import and_, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import (
    Appointment,
    Doctor,
    Hospital,
    HospitalDoctor,
    NotificationType,
    Pharmacy,
    Role,
    User,
)
from app.models.chat import ChatMessage, Conversation
from app.services.common import ServiceError, notify

MAX_TEXT = 2000


async def _doctor_of(db: AsyncSession, user: User) -> Doctor | None:
    if not user.has_role(Role.DOCTOR):
        return None
    return await db.scalar(select(Doctor).where(Doctor.user_id == user.id, Doctor.accepted.is_(True)))


async def _hospital_of(db: AsyncSession, user: User) -> Hospital | None:
    if not user.has_role(Role.HOSPITAL):
        return None
    return await db.scalar(select(Hospital).where(Hospital.owner_id == user.id, Hospital.accepted.is_(True)))


async def _pharmacy_of(db: AsyncSession, user: User) -> Pharmacy | None:
    if not user.has_role(Role.PHARMACY):
        return None
    return await db.scalar(select(Pharmacy).where(Pharmacy.owner_id == user.id, Pharmacy.accepted.is_(True)))


async def _had_appointment(db: AsyncSession, patient_id: uuid.UUID, doctor: Doctor) -> bool:
    return bool(await db.scalar(select(Appointment.id).where(Appointment.patient_id == patient_id, Appointment.doctor_id == doctor.id).limit(1)))


async def _same_hospital(db: AsyncSession, a: Doctor, b: Doctor) -> bool:
    ha = select(HospitalDoctor.hospital_id).where(HospitalDoctor.doctor_id == a.id)
    return bool(await db.scalar(select(HospitalDoctor.id).where(HospitalDoctor.doctor_id == b.id, HospitalDoctor.hospital_id.in_(ha)).limit(1)))


async def _works_at(db: AsyncSession, doctor: Doctor, hospital: Hospital) -> bool:
    return bool(await db.scalar(select(HospitalDoctor.id).where(HospitalDoctor.doctor_id == doctor.id, HospitalDoctor.hospital_id == hospital.id)))


def _is_admin(u: User) -> bool:
    return u.has_role(Role.ADMIN) or u.has_role(Role.CUSTOMER_SERVICE)


async def can_start(db: AsyncSession, me: User, other: User) -> str | None:
    """Returns None when allowed, otherwise the reason it isn't."""
    if me.id == other.id:
        return "You can't message yourself"
    if _is_admin(me) or _is_admin(other):
        return None

    my_doc, their_doc = await _doctor_of(db, me), await _doctor_of(db, other)
    my_hosp, their_hosp = await _hospital_of(db, me), await _hospital_of(db, other)
    my_pharm, their_pharm = await _pharmacy_of(db, me), await _pharmacy_of(db, other)

    # patient <-> doctor
    if their_doc and await _had_appointment(db, me.id, their_doc):
        return None
    if my_doc and await _had_appointment(db, other.id, my_doc):
        return None
    # doctor <-> doctor at the same hospital
    if my_doc and their_doc and await _same_hospital(db, my_doc, their_doc):
        return None
    # doctor <-> hospital
    if my_doc and their_hosp and await _works_at(db, my_doc, their_hosp):
        return None
    if my_hosp and their_doc and await _works_at(db, their_doc, my_hosp):
        return None
    # anyone -> accepted pharmacy or hospital (asking about stock, departments, visits)
    if their_pharm or their_hosp:
        return None
    if my_pharm or my_hosp:
        # a pharmacy or hospital may write back to anyone, but only start with its own people
        return "A pharmacy or hospital can reply to patients, but patients start the conversation"
    if their_doc:
        return "You can message a doctor after booking an appointment with them"
    return "You can only message people you have a care relationship with"


def _pair(a: uuid.UUID, b: uuid.UUID) -> tuple[uuid.UUID, uuid.UUID]:
    return (a, b) if str(a) < str(b) else (b, a)


async def get_conversation(db: AsyncSession, me: User, other: User) -> Conversation | None:
    a, b = _pair(me.id, other.id)
    return await db.scalar(select(Conversation).where(Conversation.user_a_id == a, Conversation.user_b_id == b))


async def start_or_get(db: AsyncSession, me: User, other: User, subject: str = "") -> Conversation:
    conv = await get_conversation(db, me, other)
    if conv:
        return conv
    reason = await can_start(db, me, other)
    if reason:
        raise ServiceError(reason, 403)
    a, b = _pair(me.id, other.id)
    conv = Conversation(user_a_id=a, user_b_id=b, subject=(subject or "").strip()[:120])
    db.add(conv)
    await db.commit()
    return await db.scalar(select(Conversation).where(Conversation.id == conv.id))


async def my_conversations(db: AsyncSession, me: User) -> list[tuple[Conversation, ChatMessage | None, int]]:
    """(conversation, last message, unread count) ordered by last activity."""
    convs = (
        await db.scalars(
            select(Conversation)
            .where(or_(Conversation.user_a_id == me.id, Conversation.user_b_id == me.id))
            .order_by(Conversation.last_message_at.desc())
        )
    ).all()
    out = []
    for c in convs:
        last = await db.scalar(select(ChatMessage).where(ChatMessage.conversation_id == c.id).order_by(ChatMessage.sent_at.desc()).limit(1))
        unread = await db.scalar(
            select(func.count()).select_from(ChatMessage).where(
                ChatMessage.conversation_id == c.id, ChatMessage.sender_id != me.id, ChatMessage.read_at.is_(None)
            )
        )
        out.append((c, last, int(unread or 0)))
    return out


async def _member(db: AsyncSession, me: User, conversation_id: uuid.UUID) -> Conversation:
    conv = await db.get(Conversation, conversation_id)
    if conv is None or me.id not in (conv.user_a_id, conv.user_b_id):
        raise ServiceError("Conversation not found", 404)
    return conv


async def messages(db: AsyncSession, me: User, conversation_id: uuid.UUID, *, after: datetime | None = None, limit: int = 50) -> list[ChatMessage]:
    conv = await _member(db, me, conversation_id)
    stmt = select(ChatMessage).where(ChatMessage.conversation_id == conv.id)
    if after:
        stmt = stmt.where(ChatMessage.sent_at > after)
    rows = list((await db.scalars(stmt.order_by(ChatMessage.sent_at.desc()).limit(limit))).all())
    rows.reverse()
    # reading marks the other side's messages as read
    now = datetime.now(timezone.utc)
    changed = False
    for m in rows:
        if m.sender_id != me.id and m.read_at is None:
            m.read_at = now
            changed = True
    if changed:
        await db.commit()
    return rows


async def send(db: AsyncSession, me: User, conversation_id: uuid.UUID, text: str) -> ChatMessage:
    text = (text or "").strip()
    if not text:
        raise ServiceError("Message can't be empty")
    if len(text) > MAX_TEXT:
        raise ServiceError(f"Message is longer than {MAX_TEXT} characters")
    conv = await _member(db, me, conversation_id)
    msg = ChatMessage(conversation_id=conv.id, sender_id=me.id, text=text)
    conv.last_message_at = datetime.now(timezone.utc)
    db.add(msg)
    other_id = conv.user_b_id if conv.user_a_id == me.id else conv.user_a_id
    notify(db, other_id, NotificationType.NEW_MESSAGE, f"New message from {me.name}", link=f"/chat/{conv.id}")
    await db.commit()
    return await db.scalar(select(ChatMessage).where(ChatMessage.id == msg.id))


async def unread_total(db: AsyncSession, me: User) -> int:
    mine = select(Conversation.id).where(or_(Conversation.user_a_id == me.id, Conversation.user_b_id == me.id))
    n = await db.scalar(
        select(func.count()).select_from(ChatMessage).where(
            and_(ChatMessage.conversation_id.in_(mine), ChatMessage.sender_id != me.id, ChatMessage.read_at.is_(None))
        )
    )
    return int(n or 0)


async def contacts(db: AsyncSession, me: User) -> list[dict]:
    """People this user may start a conversation with, grouped by relationship. Used by the 'new message' screen."""
    out: list[dict] = []
    seen: set[uuid.UUID] = set()

    def add(user: User, role: str, context: str):
        if user.id in seen or user.id == me.id:
            return
        seen.add(user.id)
        out.append({"user": user, "role": role, "context": context})

    # my doctors (as a patient)
    appts = await db.scalars(select(Appointment).where(Appointment.patient_id == me.id).order_by(Appointment.day.desc()))
    for a in appts:
        add(a.doctor.user, "Doctor", f"{a.doctor.specialty.name} · visit on {a.day.isoformat()}")

    my_doc = await _doctor_of(db, me)
    if my_doc:
        # my patients
        for a in await db.scalars(select(Appointment).where(Appointment.doctor_id == my_doc.id).order_by(Appointment.day.desc())):
            add(a.patient, "Patient", f"visit on {a.day.isoformat()}")
        # hospitals I work at, and colleagues there
        for link in await db.scalars(select(HospitalDoctor).where(HospitalDoctor.doctor_id == my_doc.id)):
            h = await db.get(Hospital, link.hospital_id)
            if h and h.accepted:
                add(h.owner, "Hospital", h.name)
                for peer in await db.scalars(select(HospitalDoctor).where(HospitalDoctor.hospital_id == h.id)):
                    if peer.doctor_id != my_doc.id:
                        add(peer.doctor.user, "Doctor", f"{peer.doctor.specialty.name} at {h.name}")

    my_hosp = await _hospital_of(db, me)
    if my_hosp:
        for link in my_hosp.doctors:
            add(link.doctor.user, "Doctor", link.department or link.doctor.specialty.name)

    my_pharm = await _pharmacy_of(db, me)
    if my_pharm or my_hosp:
        # existing conversations only (patients start those)
        for c, _, _ in await my_conversations(db, me):
            add(c.other(me.id), "Patient", "wrote to you")

    # support
    admins = await db.scalars(select(User).where(User.roles.any(role=Role.ADMIN)).limit(1))
    for a in admins:
        add(a, "Support", "HealthHub team")
    return out
