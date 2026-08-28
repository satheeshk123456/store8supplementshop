"""
Admin auth: the Flutter admin app signs in with Firebase Auth (email/password) and sends the
resulting ID token as `Authorization: Bearer <token>` on every admin request. We verify that
token with the Admin SDK (this checks the cryptographic signature + expiry — nothing here trusts
the client) and then additionally require the uid to be listed in the `admins` Firestore
collection. That second check means creating a Firebase Auth account is *not* enough to get
admin access by itself — you also have to be explicitly added as an admin (defense in depth).
"""
import logging

from fastapi import Header, HTTPException, status
from firebase_admin import auth as firebase_auth

from app.firebase import get_db

logger = logging.getLogger("store8")


class CurrentAdmin:
    def __init__(self, uid: str, email: str, name: str, role: str):
        self.uid = uid
        self.email = email
        self.name = name
        self.role = role


def get_current_admin(authorization: str | None = Header(default=None)) -> CurrentAdmin:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing bearer token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    token = authorization.split(" ", 1)[1].strip()

    try:
        decoded = firebase_auth.verify_id_token(token, check_revoked=True)
    except firebase_auth.RevokedIdTokenError:
        raise HTTPException(status_code=401, detail="Session revoked, please log in again")
    except firebase_auth.ExpiredIdTokenError:
        raise HTTPException(status_code=401, detail="Session expired, please log in again")
    except Exception:
        logger.warning("Rejected invalid ID token")
        raise HTTPException(status_code=401, detail="Invalid authentication token")

    uid = decoded["uid"]
    db = get_db()
    admin_doc = db.collection("admins").document(uid).get()
    if not admin_doc.exists or not admin_doc.to_dict().get("is_active", False):
        raise HTTPException(status_code=403, detail="This account is not authorized as an admin")

    data = admin_doc.to_dict()
    return CurrentAdmin(
        uid=uid,
        email=data.get("email", decoded.get("email", "")),
        name=data.get("name", ""),
        role=data.get("role", "staff"),
    )


"""
Customer auth (optional login/registration on the storefront): unlike admins, there's no
allow-list collection to additionally check — anyone can register a Firebase Auth account and
immediately use it, same as any normal e-commerce login. It exists purely so a customer can see
their own order history under their own account; guest checkout (order_number + phone,
see routers/orders.py) keeps working exactly as before and is completely unaffected by this.
"""


class CurrentCustomer:
    def __init__(self, uid: str, email: str):
        self.uid = uid
        self.email = email


def _verify_customer_token(authorization: str | None) -> dict | None:
    if not authorization or not authorization.lower().startswith("bearer "):
        return None
    token = authorization.split(" ", 1)[1].strip()
    try:
        return firebase_auth.verify_id_token(token, check_revoked=True)
    except Exception:
        return None


def get_current_customer(authorization: str | None = Header(default=None)) -> CurrentCustomer:
    """Required: raises 401 if there's no valid, logged-in customer session."""
    decoded = _verify_customer_token(authorization)
    if decoded is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Please log in to continue",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return CurrentCustomer(uid=decoded["uid"], email=decoded.get("email", ""))


def get_current_customer_optional(authorization: str | None = Header(default=None)) -> CurrentCustomer | None:
    """Optional: returns None (never raises) when there's no/invalid token — for endpoints that
    behave the same for guests and logged-in customers but want to know which one it is."""
    decoded = _verify_customer_token(authorization)
    if decoded is None:
        return None
    return CurrentCustomer(uid=decoded["uid"], email=decoded.get("email", ""))
