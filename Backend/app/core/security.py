import re
import secrets
import uuid
from datetime import datetime, timedelta, timezone

import bcrypt
import jwt

from app.core.config import settings

# Same password policy the old backend enforced:
# at least 8 chars, one lowercase, one uppercase, one digit, one symbol from the set.
PASSWORD_REGEX = re.compile(r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[_#$^+=!*()@%&]).{8,}$")
PASSWORD_RULE_MESSAGE = (
    "Password must be at least 8 characters and contain an uppercase letter, "
    "a lowercase letter, a number and a symbol [_#$^+=!*()@%&]"
)

# Egyptian national ID: 14 digits, starts with 2 or 3, contains a valid birth date
NATIONAL_ID_REGEX = re.compile(r"^[23]\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])\d{7}$")
# Egyptian mobile numbers
PHONE_REGEX = re.compile(r"^(?:\+20|0)?1[0125]\d{8}$")


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(password: str, password_hash: str) -> bool:
    try:
        return bcrypt.checkpw(password.encode("utf-8"), password_hash.encode("utf-8"))
    except ValueError:
        return False


def create_access_token(*, user_id: uuid.UUID, email: str, roles: list[str]) -> tuple[str, datetime]:
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=settings.jwt_expire_minutes)
    payload = {
        "sub": str(user_id),
        "email": email,
        "roles": roles,
        "exp": expires_at,
        "iat": datetime.now(timezone.utc),
        "jti": uuid.uuid4().hex,
    }
    token = jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)
    return token, expires_at


def decode_access_token(token: str) -> dict:
    """Raises jwt.PyJWTError on any problem."""
    return jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])


def generate_opaque_token(nbytes: int = 32) -> str:
    return secrets.token_urlsafe(nbytes)
