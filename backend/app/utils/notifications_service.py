"""Notification dispatcher service."""
import os
import json
from app.extensions import db
from app.models.notification import Notification


def send_push_notification(user, title, message, data=None):
    """
    Sends a push notification to the user's FCM token.
    If firebase-admin is not initialized or configured, logs the notification and
    inserts it in the local notification list as a fallback.
    """
    # 1. Add to local db notifications
    try:
        local_notif = Notification(
            user_id=user.id,
            title=title,
            message=message,
            type='alert',
            data=json.dumps(data) if data else None
        )
        db.session.add(local_notif)
        db.session.commit()
    except Exception as e:
        print(f"[Notifications] Error saving local notification: {e}")

    # 2. Emit via local Socket.IO so if user is currently online they get a real-time banner
    try:
        from app.extensions import socketio
        socketio.emit('notification_sent', {
            'user_id': user.id,
            'title': title,
            'message': message,
            'data': data
        }, namespace='/')
        print(f"[Notifications] Emitted socket notification_sent to user {user.id}")
    except Exception as e:
        print(f"[Notifications] Error emitting notification over Socket.IO: {e}")

    # 3. Try sending via FCM if token exists
    if not user.fcm_token:
        print(f"[Notifications] No FCM token found for user {user.email}. Skipped push.")
        return False

    try:
        import firebase_admin
        from firebase_admin import messaging
        
        # Check if initialized
        try:
            firebase_admin.get_app()
        except ValueError:
            firebase_admin.initialize_app()
            
        # Construct message
        fcm_message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=message,
            ),
            data={k: str(v) for k, v in (data or {}).items()} if data else None,
            token=user.fcm_token,
        )
        response = messaging.send(fcm_message)
        print(f"[Notifications] Successfully sent FCM message to {user.email}: {response}")
        return True
    except Exception as e:
        print(f"[Notifications] FCM push failed for user {user.email} (FCM not configured/auth error): {e}")
        return False
