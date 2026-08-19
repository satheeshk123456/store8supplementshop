"""
Push a notification to every registered admin device the moment an order is placed.

This is plain FCM (Firebase Cloud Messaging) via the Admin SDK — no Cloud Functions involved,
which is what lets this run on a normal free-tier host with no billing account required.

Delivery when the admin app is closed or the phone has no signal is handled entirely by FCM
itself, not by this code: `messaging.send()` hands the message to Google's push infrastructure,
which queues it against the device token and delivers it (a) to the OS-level notification tray
even if the app process isn't running, and (b) as soon as the device reconnects if it was
offline. That's why nothing special is needed here for the "network was off, now on" case —
it's a guarantee FCM gives for free as long as the Flutter app registers a token and (for
Android 8+) has a proper high-importance notification channel, which the app sets up on launch.
"""
import logging

from firebase_admin import messaging

from app.firebase import get_db

logger = logging.getLogger("store8")


def notify_admins_new_order(order_id: str, order_number: str, total_amount: float, customer_name: str) -> bool:
    db = get_db()
    tokens_snap = db.collection("device_tokens").stream()
    tokens = [d.id for d in tokens_snap]
    if not tokens:
        logger.warning("New order %s but no admin device tokens registered", order_number)
        return False

    message = messaging.MulticastMessage(
        tokens=tokens,
        notification=messaging.Notification(
            title="New order received",
            body=f"{order_number} · {customer_name} · ₹{total_amount:.0f}",
        ),
        data={
            "type": "new_order",
            "order_id": order_id,
            "order_number": order_number,
        },
        android=messaging.AndroidConfig(
            priority="high",
            notification=messaging.AndroidNotification(channel_id="orders_high_importance", sound="default"),
        ),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(aps=messaging.Aps(sound="default", content_available=True))
        ),
    )

    response = messaging.send_each_for_multicast(message)
    logger.info("FCM sent for order %s: %s success / %s failure", order_number, response.success_count, response.failure_count)

    # Prune tokens that are no longer valid (app uninstalled, token rotated, etc.)
    stale = []
    for token, result in zip(tokens, response.responses):
        if not result.success:
            code = getattr(result.exception, "code", "")
            msg = getattr(result.exception, "message", str(result.exception))
            logger.warning("FCM failure for token %s...: code=%s message=%s", token[:12], code, msg)
            if code in ("NOT_FOUND", "UNREGISTERED", "INVALID_ARGUMENT"):
                stale.append(token)
    for token in stale:
        db.collection("device_tokens").document(token).delete()
    if stale:
        logger.info("Pruned %s stale device tokens", len(stale))

    return response.success_count > 0
