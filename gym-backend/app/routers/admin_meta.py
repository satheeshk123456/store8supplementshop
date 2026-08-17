from fastapi import APIRouter, Depends

from app.security import CurrentAdmin, get_current_admin

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/me")
def whoami(admin: CurrentAdmin = Depends(get_current_admin)):
    """Flutter app calls this right after Firebase sign-in to confirm admin access and get profile."""
    return {"uid": admin.uid, "email": admin.email, "name": admin.name, "role": admin.role}
