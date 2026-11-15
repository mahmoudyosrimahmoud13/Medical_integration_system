import uuid
from datetime import datetime

from fastapi import APIRouter, Query, Request

from app.core.deps import DB, CurrentUser, image_url
from app.models import Role, User
from app.models.chat import ChatMessage, Conversation
from app.schemas.v1 import (
    ChatMessageOut,
    ContactOut,
    ConversationOut,
    PersonOut,
    SendMessageIn,
    StartConversationIn,
    UnreadOut,
)
from app.services import chat as svc
from app.services.common import ServiceError

router = APIRouter(prefix="/chat", tags=["chat"])


def _role_label(u: User) -> str:
    for r, label in ((Role.ADMIN, "Support"), (Role.CUSTOMER_SERVICE, "Support"), (Role.DOCTOR, "Doctor"), (Role.HOSPITAL, "Hospital"), (Role.PHARMACY, "Pharmacy")):
        if u.has_role(r):
            return label
    return "Patient"


def _msg(m: ChatMessage, me: User) -> ChatMessageOut:
    return ChatMessageOut(id=m.id, sender_id=m.sender_id, sender_name=m.sender.name, text=m.text, sent_at=m.sent_at, read_at=m.read_at, mine=m.sender_id == me.id)


def _conv(c: Conversation, last: ChatMessage | None, unread: int, me: User, request: Request) -> ConversationOut:
    other = c.other(me.id)
    return ConversationOut(
        id=c.id,
        other=PersonOut(id=other.id, name=other.name, image_url=image_url(request, "User", other.image)),
        other_role=_role_label(other),
        subject=c.subject,
        last_message=_msg(last, me) if last else None,
        unread=unread,
        last_message_at=c.last_message_at,
    )


@router.get("/contacts", response_model=list[ContactOut])
async def contacts(me: CurrentUser, db: DB, request: Request):
    return [
        ContactOut(user_id=c["user"].id, name=c["user"].name, image_url=image_url(request, "User", c["user"].image), role=c["role"], context=c["context"])
        for c in await svc.contacts(db, me)
    ]


@router.get("/conversations", response_model=list[ConversationOut])
async def conversations(me: CurrentUser, db: DB, request: Request):
    return [_conv(c, last, unread, me, request) for c, last, unread in await svc.my_conversations(db, me)]


@router.post("/conversations", response_model=ConversationOut, status_code=201)
async def start(body: StartConversationIn, me: CurrentUser, db: DB, request: Request):
    other = await db.get(User, body.user_id)
    if other is None:
        raise ServiceError("User not found", 404)
    conv = await svc.start_or_get(db, me, other, body.subject)
    last = None
    if body.first_message:
        last = await svc.send(db, me, conv.id, body.first_message)
    return _conv(conv, last, 0, me, request)


@router.get("/conversations/{conversation_id}/messages", response_model=list[ChatMessageOut])
async def read_messages(conversation_id: uuid.UUID, me: CurrentUser, db: DB, after: datetime | None = None, limit: int = Query(50, le=200)):
    return [_msg(m, me) for m in await svc.messages(db, me, conversation_id, after=after, limit=limit)]


@router.post("/conversations/{conversation_id}/messages", response_model=ChatMessageOut, status_code=201)
async def send(conversation_id: uuid.UUID, body: SendMessageIn, me: CurrentUser, db: DB):
    return _msg(await svc.send(db, me, conversation_id, body.text), me)


@router.get("/unread", response_model=UnreadOut)
async def unread(me: CurrentUser, db: DB):
    return UnreadOut(unread=await svc.unread_total(db, me))
