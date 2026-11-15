import uuid

from fastapi import APIRouter, HTTPException, Query, Request

from app.core.deps import DB, AdminUser
from app.models import AdminLog, Role, User
from app.schemas.v1 import (
    DoctorRequestOut,
    DoctorRequestPage,
    MessageOut,
    RoleChangeIn,
    build_doctor_request,
)
from app.services import auth as auth_svc
from app.services import doctors as svc

router = APIRouter(prefix="/admin", tags=["admin"])


def _role(value: str) -> Role:
    for r in Role:
        if r.value.lower() == value.strip().lower():
            return r
    raise HTTPException(400, f"Unknown role. Use one of: {', '.join(r.value for r in Role)}")


@router.get("/doctor-requests", response_model=DoctorRequestPage)
async def doctor_requests(admin: AdminUser, db: DB, request: Request, page: int = Query(0, ge=0)):
    items, total = await svc.pending_requests(db, page)
    return DoctorRequestPage(items=[build_doctor_request(d, request) for d in items], total=total, page=page)


@router.post("/doctor-requests/{doctor_id}/accept", response_model=DoctorRequestOut)
async def accept(doctor_id: uuid.UUID, admin: AdminUser, db: DB, request: Request):
    return build_doctor_request(await svc.review_request(db, admin, doctor_id, True), request)


@router.post("/doctor-requests/{doctor_id}/reject", response_model=DoctorRequestOut)
async def reject(doctor_id: uuid.UUID, admin: AdminUser, db: DB, request: Request):
    return build_doctor_request(await svc.review_request(db, admin, doctor_id, False), request)


async def _change_role(body: RoleChangeIn, admin: User, db, add: bool) -> MessageOut:
    role = _role(body.role)
    if role == Role.ADMIN and not admin.has_role(Role.ADMIN):
        raise HTTPException(403, "Only admins can manage the Admin role")
    user = await auth_svc.get_user_by_email(db, body.email)
    if user is None:
        raise HTTPException(404, "User not found")
    if add:
        await auth_svc.add_role(db, user, role)
    else:
        await auth_svc.remove_role(db, user, role)
    db.add(AdminLog(admin_id=admin.id, action=("add_role:" if add else "remove_role:") + role.value, target=user.email))
    await db.commit()
    return MessageOut(message=f"{'Added' if add else 'Removed'} {role.value} for {user.email}")


@router.post("/roles/add", response_model=MessageOut)
async def add_role(body: RoleChangeIn, admin: AdminUser, db: DB):
    return await _change_role(body, admin, db, True)


@router.post("/roles/remove", response_model=MessageOut)
async def remove_role(body: RoleChangeIn, admin: AdminUser, db: DB):
    return await _change_role(body, admin, db, False)


@router.post("/users/{user_id}/block", response_model=MessageOut)
async def block(user_id: uuid.UUID, admin: AdminUser, db: DB, blocked: bool = True):
    user = await db.get(User, user_id)
    if user is None:
        raise HTTPException(404, "User not found")
    if user.id == admin.id:
        raise HTTPException(400, "You can't block yourself")
    user.is_blocked = blocked
    db.add(AdminLog(admin_id=admin.id, action="block" if blocked else "unblock", target=user.email))
    await db.commit()
    return MessageOut(message="Blocked" if blocked else "Unblocked")
