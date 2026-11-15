from fastapi import APIRouter, File, Request, UploadFile

from app.core.deps import DB, CurrentUser, public_base_url
from app.schemas.v1 import (
    ChangePasswordIn,
    ForgotPasswordIn,
    LoginIn,
    MessageOut,
    RegisterIn,
    ResetPasswordIn,
    TokenOut,
    UserOut,
)
from app.services import auth as svc

router = APIRouter(tags=["auth"])


@router.post("/auth/register", response_model=UserOut, status_code=201)
async def register(body: RegisterIn, db: DB, request: Request):
    user = await svc.register_user(
        db,
        name=body.name,
        email=body.email,
        password=body.password,
        phone=body.phone,
        birth_date=body.birth_date,
        national_id=body.national_id,
        gender_male=body.gender == "male",
        area_id=body.area_id,
        confirm_base_url=public_base_url(request),
    )
    return UserOut.build(await svc.get_user_by_email(db, user.email), request)


@router.post("/auth/login", response_model=TokenOut)
async def login(body: LoginIn, db: DB, request: Request):
    user = await svc.authenticate(db, body.login, body.password)
    token, expires = svc.issue_token(user)
    return TokenOut(access_token=token, expires_at=expires, user=UserOut.build(user, request))


@router.post("/auth/forgot-password", response_model=MessageOut)
async def forgot_password(body: ForgotPasswordIn, db: DB):
    await svc.start_password_reset(db, body.email)
    return MessageOut(message="If this email is registered, a reset code was sent to it")


@router.post("/auth/reset-password", response_model=MessageOut)
async def reset_password(body: ResetPasswordIn, db: DB):
    await svc.reset_password(db, body.token, body.new_password)
    return MessageOut(message="Password changed, you can log in now")


@router.get("/auth/confirm-email", response_model=MessageOut)
async def confirm_email(token: str, db: DB):
    await svc.confirm_email(db, token)
    return MessageOut(message="Email confirmed")


@router.post("/auth/change-password", response_model=MessageOut)
async def change_password(body: ChangePasswordIn, user: CurrentUser, db: DB):
    await svc.change_password(db, user, body.old_password, body.new_password)
    return MessageOut(message="Password changed")


@router.get("/users/me", response_model=UserOut, tags=["users"])
async def me(user: CurrentUser, request: Request):
    return UserOut.build(user, request)


@router.put("/users/me/photo", response_model=UserOut, tags=["users"])
async def change_photo(user: CurrentUser, db: DB, request: Request, image: UploadFile = File(...)):
    await svc.change_photo(db, user, image)
    return UserOut.build(user, request)
