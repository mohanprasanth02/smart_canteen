"""Token model for order tokens."""
import random
from datetime import datetime, timezone
from app.extensions import db


class Token(db.Model):
    __tablename__ = 'tokens'

    id = db.Column(db.Integer, primary_key=True)
    token_number = db.Column(db.String(20), unique=True, nullable=False, index=True)  # TKN-451
    order_db_id = db.Column(db.Integer, db.ForeignKey('orders.id'), unique=True, nullable=False, index=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    qr_data = db.Column(db.Text, nullable=True)  # JSON string with verification hash
    is_used = db.Column(db.Boolean, default=False, nullable=False)
    used_at = db.Column(db.DateTime, nullable=True)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    expires_at = db.Column(db.DateTime, nullable=True)

    @staticmethod
    def generate_token_number():
        """Generate unique token number like TKN-451."""
        while True:
            num = random.randint(100, 999)
            token_str = f'TKN-{num}'
            existing = Token.query.filter_by(
                token_number=token_str,
                is_used=False,
            ).first()
            if not existing:
                return token_str

    def to_dict(self):
        return {
            'id': self.id,
            'token_number': self.token_number,
            'order_db_id': self.order_db_id,
            'user_id': self.user_id,
            'qr_data': self.qr_data,
            'is_used': self.is_used,
            'used_at': self.used_at.isoformat() if self.used_at else None,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self):
        return f'<Token {self.token_number} used={self.is_used}>'
