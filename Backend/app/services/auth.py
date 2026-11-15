import uuid
from datetime import date, datetime, timedelta, timezone

from fastapi import UploadFile
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.security import (
    NATIONAL_ID_REGEX,
    PASSWORD_REGEX,
    PASSWORD_RULE_MESSAGE,
    PHONE_REGEX,
    create_access_token,
    generate_opaque_token,
    hash_password,
    verify_password,
)
from app.models import Area, PasswordResetToken, Role, User, UserRole
from app.services.common import IMAGE_EXTENSIONS, ServiceError, save_upload, send_email


async def get_user_by_email(db: AsyncSession, email: str) -> User | None:
    return await db.scalar(select(User).where(func.lower(User.email) == (email or "").strip().lower()))


async def find_user_by_login(db: AsyncSession, login: str) -> User | None:
    login = (login or "").strip().lower()
    return await db.scalar(select(User).where(or_(func.lower(User.email) == login, func.lower(User.username) == login)))


def check_password_rules(password: str) -> None:
    if not PASSWORD_REGEX.match(password or ""):
        raise ServiceError(PASSWORD_RULE_MESSAGE)


async def _unique_username(db: AsyncSession, email: str) -> str:
    base = email.split("@")[0].lower() or "user"
    candidate, n = base, 1
    while await db.scalar(select(User.id).where(User.username == candidate)):
        n += 1
        candidate = f"{base}{n}"
    return candidate


async def register_user(
    db: AsyncSession,
    *,
    name: str,
    email: str,
    password: str,
    phone: str,
    birth_date: date,
    national_id: str,
    gender_male: bool,
    area_key: str | None = None,
    area_id: uuid.UUID | None = None,
    image: UploadFile | None = None,
    confirm_base_url: str = "",
) -> User:
    name = (name or "").strip()
    email = (email or "").strip().lower()
    if len(name) < 3:
        raise ServiceError("Must Enter Name(First Name,Mid Name,Last Name)")
    if "@" not in email:
        raise ServiceError("Must Enter Email (***@example.com)")
    check_password_rules(password)
    if not PHONE_REGEX.match(phone or ""):
        raise ServiceError("Phone must be an Egyptian mobile number: 01[0|1|2|5]********")
    if not NATIONAL_ID_REGEX.match(national_id or ""):
        raise ServiceError("National ID Required (14 digits)")
    if birth_date >= date.today():
        raise ServiceError("Must Select BirthDay")

    if await get_user_by_email(db, email):
        raise ServiceError("The Email Is Registered")

    area = None
    if area_id:
        area = await db.get(Area, area_id)
    elif area_key:
        area = await db.scalar(select(Area).where(func.lower(Area.key) == area_key.strip().lower()).limit(1))
    if area is None:
        raise ServiceError("No Area by This Name")

    if await db.scalar(select(User.id).where(User.national_id == national_id)):
        raise ServiceError("The National ID Is Registered")

    image_name = await save_upload(image, "User", IMAGE_EXTENSIONS) if image is not None else None

    user = User(
        email=email,
        username=await _unique_username(db, email),
        password_hash=hash_password(password),
        name=name,
        phone=phone,
        national_id=national_id,
        birth_date=birth_date,
        gender_male=gender_male,
        area_id=area.id,
        image=image_name,
        email_confirmed=not settings.require_email_confirmation,
        roles=[UserRole(role=Role.PATIENT)],
    )
    db.add(user)
    await db.flush()

    if settings.require_email_confirmation:
        token = await _create_token(db, user, purpose="confirm", hours=48)
        await send_email(
            user.email,
            "Confirm your HealthHub email",
            f"Hello {user.name},\n\nConfirm your email by opening:\n{confirm_base_url}/api/v1/auth/confirm-email?token={token}\n",
        )
    await db.commit()
    return user


async def authenticate(db: AsyncSession, login: str, password: str) -> User:
    user = await find_user_by_login(db, login)
    if user is None or not verify_password(password or "", user.password_hash):
        raise ServiceError("Email Or Password Incorrect", 401)
    if user.is_blocked:
        raise ServiceError("You are blocked", 403)
    if not user.email_confirmed:
        raise ServiceError("need Confirm Mail", 403)
    return user


def issue_token(user: User) -> tuple[str, datetime]:
    return create_access_token(user_id=user.id, email=user.email, roles=user.role_names)


async def _create_token(db: AsyncSession, user: User, purpose: str, hours: int) -> str:
    token = generate_opaque_token()
    db.add(
        PasswordResetToken(
            user_id=user.id,
            token=token,
            purpose=purpose,
            expires_at=datetime.now(timezone.utc) + timedelta(hours=hours),
        )
    )
    return token


async def _consume_token(db: AsyncSession, token: str, purpose: str) -> User:
    row = await db.scalar(
        select(PasswordResetToken).where(PasswordResetToken.token == token, PasswordResetToken.purpose == purpose)
    )
    if row is None or row.used:
        raise ServiceError("Invalid or already used link")
    expires = row.expires_at if row.expires_at.tzinfo else row.expires_at.replace(tzinfo=timezone.utc)
    if expires < datetime.now(timezone.utc):
        raise ServiceError("This link has expired")
    row.used = True
    user = await db.get(User, row.user_id)
    if user is None:
        raise ServiceError("User not found", 404)
    return user


async def start_password_reset(db: AsyncSession, email: str) -> None:
    """Emails a reset code. Silent when the email is unknown, so accounts can't be discovered."""
    user = await get_user_by_email(db, email)
    if user is None:
        return
    token = await _create_token(db, user, purpose="reset", hours=1)
    await db.commit()
    await send_email(
        user.email,
        "Reset your HealthHub password",
        f"Hello {user.name},\n\nUse this code to reset your password (valid for 1 hour):\n\n{token}\n\n"
        "If you did not ask for this, ignore this email.\n",
    )


async def reset_password(db: AsyncSession, token: str, new_password: str) -> None:
    check_password_rules(new_password)
    user = await _consume_token(db, token, "reset")
    user.password_hash = hash_password(new_password)
    await db.commit()


async def confirm_email(db: AsyncSession, token: str) -> None:
    user = await _consume_token(db, token, "confirm")
    user.email_confirmed = True
    await db.commit()


async def change_password(db: AsyncSession, user: User, old_password: str, new_password: str) -> None:
    if not verify_password(old_password or "", user.password_hash):
        raise ServiceError("Old password is incorrect")
    check_password_rules(new_password)
    user.password_hash = hash_password(new_password)
    await db.commit()


async def change_photo(db: AsyncSession, user: User, image: UploadFile) -> str:
    user.image = await save_upload(image, "User", IMAGE_EXTENSIONS)
    await db.commit()
    return user.image


async def add_role(db: AsyncSession, user: User, role: Role) -> None:
    if not user.has_role(role):
        user.roles.append(UserRole(role=role))


async def remove_role(db: AsyncSession, user: User, role: Role) -> None:
    for r in list(user.roles):
        if r.role == role:
            user.roles.remove(r)
