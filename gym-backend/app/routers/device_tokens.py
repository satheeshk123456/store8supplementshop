from fastapi import APIRouter, Depends

from app.firebase import get_db, firestore
from app.schemas import DeviceTokenIn
from app.security import get_current_admin

router = APIRouter(prefix="/admin/device-tokens", tags=["device-tokens"])


@router.post("", status_code=204)
def register_device_token(payload: DeviceTokenIn, admin=Depends(get_current_admin)):
    """Flutter app calls this right after login (and whenever FCM hands it a refreshed token)."""
    db = get_db()
    db.collection("device_tokens").document(payload.token).set(
        {
            "admin_uid": admin.uid,
            "platform": payload.platform,
            "created_at": firestore.SERVER_TIMESTAMP,
            "last_seen_at": firestore.SERVER_TIMESTAMP,
        },
        merge=True,
    )


@router.delete("/{token}", status_code=204)
def unregister_device_token(token: str, admin=Depends(get_current_admin)):
    """Called on logout so a signed-out device stops receiving pushes."""
    db = get_db()
    db.collection("device_tokens").document(token).delete()
