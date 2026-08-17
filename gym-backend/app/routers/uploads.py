from fastapi import APIRouter, Depends, File, HTTPException, UploadFile

from app.storage_client import upload_image
from app.schemas import UploadResponse
from app.security import get_current_admin

router = APIRouter(prefix="/admin/uploads", tags=["uploads"])

ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_BYTES = 5 * 1024 * 1024  # 5 MB


@router.post("/{folder}", response_model=UploadResponse)
async def upload(folder: str, file: UploadFile = File(...), admin=Depends(get_current_admin)):
    """
    Used by both the admin app's 'add product' flow and (for brand logos) the brand form —
    same upload path either way, matching how the client asked images to be added consistently.
    `folder` is a simple label like "products" or "brands", just to organize the Storage
    bucket — it does not affect access control.
    """
    if folder not in {"products", "brands", "categories"}:
        raise HTTPException(400, "Invalid upload folder")
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(415, "Only JPEG, PNG or WEBP images are allowed")

    body = await file.read()
    if len(body) > MAX_BYTES:
        raise HTTPException(413, "Image must be under 5 MB")

    result = upload_image(body, folder=folder)
    return UploadResponse(url=result["secure_url"], public_id=result["public_id"])
