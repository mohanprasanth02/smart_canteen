"""Chat models for live support."""
from datetime import datetime, timezone
from app.extensions import db


class ChatRoom(db.Model):
    __tablename__ = 'chat_rooms'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    order_id = db.Column(db.Integer, db.ForeignKey('orders.id'), nullable=True, index=True)
    status = db.Column(db.String(20), default='active', nullable=False)  # active, closed
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = db.Column(
        db.DateTime,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    # Relationships
    messages = db.relationship('ChatMessage', backref='room', cascade='all, delete-orphan', order_by='ChatMessage.created_at')
    user = db.relationship('User', backref=db.backref('chat_rooms', lazy='dynamic'))
    order = db.relationship('Order', backref=db.backref('chat_room', uselist=False))

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'student_name': self.user.full_name if self.user else 'Unknown Student',
            'order_id': self.order.order_id if self.order else None,
            'order_db_id': self.order_id,
            'status': self.status,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }


class ChatMessage(db.Model):
    __tablename__ = 'chat_messages'

    id = db.Column(db.Integer, primary_key=True)
    room_id = db.Column(db.Integer, db.ForeignKey('chat_rooms.id'), nullable=False, index=True)
    sender_id = db.Column(db.Integer, nullable=True)  # ID of user/admin sending the message
    sender_role = db.Column(db.String(20), nullable=False)  # student, admin, system
    message = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    def to_dict(self):
        return {
            'id': self.id,
            'room_id': self.room_id,
            'sender_id': self.sender_id,
            'sender_role': self.sender_role,
            'message': self.message,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }
