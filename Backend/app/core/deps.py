import uuid
from collections.abc import Callable
from typing import Annotated

import jwt
from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.security import decode_access_token
from app.db.session import get_db
from app.models import Doctor, Role, User

bearer_scheme = HTTPBearer(auto_error=False)

DB = Annotated[AsyncSession, Depends(get_db)]


async def get_current_user(
    db: DB,
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer_scheme)],
) -> User:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Not authenticated")
    try:
        payload = decode_access_token(credentials.credentials)
        user_id = uuid.UUID(payload["sub"])
    except (jwt.PyJWTError, KeyError, ValueError):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid or expired token")
    user = await db.scalar(select(User).where(User.id == user_id))
    if user is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "User no longer exists")
    if user.is_blocked:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Account is blocked")
    return user


async def get_optional_user(
    db: DB,
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer_scheme)],
) -> User | None:
    if credentials is None:
        return None
    try:
        return await get_current_user(db, credentials)
    except HTTPException:
        return None


CurrentUser = Annotated[User, Depends(get_current_user)]
OptionalUser = Annotated[User | None, Depends(get_optional_user)]


def require_roles(*roles: Role) -> Callable:
    async def checker(user: CurrentUser) -> User:
        if not any(user.has_role(r) for r in roles):
            raise HTTPException(status.HTTP_403_FORBIDDEN, f"Requires role: {', '.join(r.value for r in roles)}")
        return user

    return checker


AdminUser = Annotated[User, Depends(require_roles(Role.ADMIN, Role.CUSTOMER_SERVICE))]


async def get_current_doctor(db: DB, user: Annotated[User, Depends(require_roles(Role.DOCTOR))]) -> Doctor:
    doctor = await db.scalar(select(Doctor).where(Doctor.user_id == user.id))
    if doctor is None or not doctor.accepted:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Doctor profile not found or not accepted yet")
    return doctor


CurrentDoctor = Annotated[Doctor, Depends(get_current_doctor)]


def public_base_url(request: Request) -> str:
    if settings.public_base_url:
        return settings.public_base_url.rstrip("/")
    return str(request.base_url).rstrip("/")


def image_url(request: Request, folder: str, file_name: str | None) -> str | None:
    """Builds http://host/Image/<folder>/<file>, the same URL scheme as the old API."""
    if not file_name:
        return None
    return f"{public_base_url(request)}/Image/{folder}/{file_name}"
