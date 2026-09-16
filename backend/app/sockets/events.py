"""Socket.IO event handlers for real-time communication."""
from app.extensions import socketio
from flask_socketio import emit, join_room, leave_room

# Track connected users
connected_users = {}


@socketio.on('connect')
def handle_connect():
    """Handle new client connection."""
    print(f'[Socket.IO] Client connected')
    emit('connection_status', {'status': 'connected'})


@socketio.on('disconnect')
def handle_disconnect():
    """Handle client disconnection."""
    # Find and remove user from tracking
    sid = None
    for user_id, s in list(connected_users.items()):
        if s == sid:
            del connected_users[user_id]
            emit('user_disconnected', {
                'user_id': user_id,
                'active_users': len(connected_users),
            }, broadcast=True)
            break
    print(f'[Socket.IO] Client disconnected')


@socketio.on('user_online')
def handle_user_online(data):
    """Track user going online."""
    user_id = data.get('user_id')
    if user_id:
        connected_users[str(user_id)] = True
        emit('user_connected', {
            'user_id': user_id,
            'active_users': len(connected_users),
        }, broadcast=True)
        print(f'[Socket.IO] User {user_id} is online. Active: {len(connected_users)}')


@socketio.on('user_offline')
def handle_user_offline(data):
    """Track user going offline."""
    user_id = str(data.get('user_id', ''))
    if user_id in connected_users:
        del connected_users[user_id]
        emit('user_disconnected', {
            'user_id': user_id,
            'active_users': len(connected_users),
        }, broadcast=True)


@socketio.on('join_room')
def handle_join_room(data):
    """Join a specific room (e.g., user-specific or admin room)."""
    room = data.get('room')
    if room:
        join_room(room)
        print(f'[Socket.IO] Joined room: {room}')


@socketio.on('leave_room')
def handle_leave_room(data):
    """Leave a specific room."""
    room = data.get('room')
    if room:
        leave_room(room)


@socketio.on('ping_server')
def handle_ping(data):
    """Respond to client ping for connection health check."""
    emit('pong_server', {'status': 'alive', 'active_users': len(connected_users)})


def get_active_user_count():
    """Get count of active connected users."""
    return len(connected_users)


def init_socket_events(app):
    """Initialize socket events with app context."""
    pass  # Events are auto-registered via decorators


@socketio.on('join_chat')
def handle_join_chat(data):
    """Join a support chat room."""
    room_id = data.get('room_id')
    if room_id:
        room_name = f"chat_room_{room_id}"
        join_room(room_name)
        print(f"[Socket.IO] Client joined chat room: {room_name}")
        emit('chat_joined', {'room_id': room_id})


@socketio.on('send_chat_message')
def handle_send_chat_message(data):
    """Receive a new message from a client and broadcast it to the room."""
    from app.extensions import db
    from app.models.chat import ChatRoom, ChatMessage
    from app.models.user import User
    from datetime import datetime, timezone

    room_id = data.get('room_id')
    sender_id = data.get('sender_id')
    sender_role = data.get('sender_role')  # student or admin
    message_text = data.get('message')

    if not room_id or not message_text:
        return

    room = ChatRoom.query.get(room_id)
    if not room:
        return

    # Create message in DB
    msg = ChatMessage(
        room_id=room_id,
        sender_id=sender_id,
        sender_role=sender_role,
        message=message_text
    )
    db.session.add(msg)
    room.updated_at = datetime.now(timezone.utc)
    db.session.commit()

    room_name = f"chat_room_{room_id}"
    
    # Broadcast to room
    socketio.emit('new_chat_message', msg.to_dict(), room=room_name, namespace='/')
    print(f"[Socket.IO] Broadcasted message in {room_name}: {message_text[:30]}...")

    # If sender is admin, notify student via push notification
    if sender_role == 'admin':
        from app.utils.notifications_service import send_push_notification
        student = User.query.get(room.user_id)
        if student:
            send_push_notification(
                user=student,
                title="Support Chat",
                message=message_text,
                data={'room_id': room_id, 'type': 'chat'}
            )
