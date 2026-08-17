"""
Product image storage on Firebase Storage. Uploads always go through this backend (using the
Admin SDK / service account) — never directly from the website or app — so Storage security
rules can simply deny everything (see storage.rules) without weakening anything: the only way
in is here, gated by the same admin auth check as the rest of the admin API.

Images are resized server-side before upload (Pillow) since Storage itself doesn't transform
images the way Cloudinary did — capping dimensions keeps a beginner's uploads (a straight-from-phone-camera
5000px photo) from eating storage/bandwidth for no visual benefit.
"""
import io
import logging
import uuid

from PIL import Image, ImageOps

from app.firebase import get_bucket

logger = logging.getLogger("store8")

MAX_DIMENSION = 1600


def _resize(file_bytes: bytes) -> tuple[bytes, str]:
    img = Image.open(io.BytesIO(file_bytes))
    img = ImageOps.exif_transpose(img)  # respect phone camera orientation
    if img.mode not in ("RGB", "L"):
        img = img.convert("RGB")
    img.thumbnail((MAX_DIMENSION, MAX_DIMENSION), Image.LANCZOS)
    out = io.BytesIO()
    img.save(out, format="JPEG", quality=85, optimize=True)
    return out.getvalue(), "image/jpeg"


def upload_image(file_bytes: bytes, folder: str) -> dict:
    """Resizes, uploads to Storage, makes the object publicly readable (these are storefront
    product photos, meant to be public), and returns the public URL + storage path."""
    resized_bytes, content_type = _resize(file_bytes)

    path = f"store8/{folder}/{uuid.uuid4().hex}.jpg"
    bucket = get_bucket()
    blob = bucket.blob(path)
    blob.upload_from_string(resized_bytes, content_type=content_type)
    blob.make_public()

    return {"secure_url": blob.public_url, "public_id": path}


def delete_image(path: str) -> None:
    bucket = get_bucket()
    blob = bucket.blob(path)
    if blob.exists():
        blob.delete()
