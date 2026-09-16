"""Chat routes for support."""
from datetime import datetime, timezone
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from app.extensions import db
from app.models.chat import ChatRoom, ChatMessage
from app.models.order import Order
from app.models.user import User

chat_bp = Blueprint('chat', __name__, url_prefix='/api/chat')


@chat_bp.route('/rooms', methods=['POST'])
@jwt_required()
def create_or_get_room():
    """Create or get existing active chat room for student. Admin can also use it to get/list."""
    identity = get_jwt_identity()
    claims = get_jwt()
    role = claims.get('role', 'student')

    if role in ('admin', 'super_admin'):
        # For admins, return all active rooms
        rooms = ChatRoom.query.filter_by(status='active').order_by(ChatRoom.updated_at.desc()).all()
        return jsonify({'rooms': [r.to_dict() for r in rooms]}), 200

    user_id = int(identity)
    data = request.get_json(silent=True) or {}
    order_id = data.get('order_id')  # Optional database order ID

    # Find existing active room
    room = ChatRoom.query.filter_by(user_id=user_id, status='active').first()
    if not room:
        room = ChatRoom(
            user_id=user_id,
            order_id=order_id,
            status='active'
        )
        db.session.add(room)
        db.session.commit()

        # Add system welcome message
        welcome = ChatMessage(
            room_id=room.id,
            sender_role='system',
            message="Welcome to Smart Canteen Support. A representative will join shortly!"
        )
        db.session.add(welcome)
        db.session.commit()

    return jsonify({'room': room.to_dict()}), 200


@chat_bp.route('/rooms/active', methods=['GET'])
@jwt_required()
def get_active_rooms():
    """Get all active chat rooms (admin only)."""
    claims = get_jwt()
    if claims.get('role') not in ('admin', 'super_admin'):
        return jsonify({'error': 'Admin access required'}), 403

    rooms = ChatRoom.query.filter_by(status='active').order_by(ChatRoom.updated_at.desc()).all()
    return jsonify({'rooms': [r.to_dict() for r in rooms]}), 200


@chat_bp.route('/rooms/<int:room_id>/messages', methods=['GET'])
@jwt_required()
def get_room_messages(room_id):
    """Get all messages in a chat room."""
    identity = get_jwt_identity()
    claims = get_jwt()
    role = claims.get('role', 'student')

    room = ChatRoom.query.get(room_id)
    if not room:
        return jsonify({'error': 'Chat room not found'}), 404

    # Security check: students can only see their own chat rooms
    if role == 'student' and room.user_id != int(identity):
        return jsonify({'error': 'Access denied'}), 403

    messages = ChatMessage.query.filter_by(room_id=room_id).order_by(ChatMessage.created_at.asc()).all()
    return jsonify({'messages': [m.to_dict() for m in messages]}), 200


@chat_bp.route('/rooms/<int:room_id>/close', methods=['POST'])
@jwt_required()
def close_room(room_id):
    """Close an active chat room."""
    identity = get_jwt_identity()
    claims = get_jwt()
    role = claims.get('role', 'student')

    room = ChatRoom.query.get(room_id)
    if not room:
        return jsonify({'error': 'Chat room not found'}), 404

    if role == 'student' and room.user_id != int(identity):
        return jsonify({'error': 'Access denied'}), 403

    room.status = 'closed'
    room.updated_at = datetime.now(timezone.utc)

    # Add system message
    system_msg = ChatMessage(
        room_id=room.id,
        sender_role='system',
        message="This chat has been closed. Thank you!"
    )
    db.session.add(system_msg)
    db.session.commit()

    # Emit close event via socket
    from app.extensions import socketio
    socketio.emit('chat_room_closed', {
        'room_id': room.id,
        'user_id': room.user_id
    }, namespace='/')

    return jsonify({'message': 'Chat room closed successfully', 'room': room.to_dict()}), 200
