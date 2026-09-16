"""Payment model."""
from datetime import datetime, timezone
from app.extensions import db


class Payment(db.Model):
    __tablename__ = 'payments'

    id = db.Column(db.Integer, primary_key=True)
    order_db_id = db.Column(db.Integer, db.ForeignKey('orders.id'), unique=True, nullable=False, index=True)
    payment_method = db.Column(db.String(50), nullable=False)  # upi, qr, cash, wallet
    status = db.Column(
        db.String(20),
        default='pending',
        nullable=False,
    )  # pending, paid, failed, refunded
    transaction_id = db.Column(db.String(100), nullable=True, unique=True)
    amount = db.Column(db.Float, nullable=False)
    paid_at = db.Column(db.DateTime, nullable=True)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    def to_dict(self):
        return {
            'id': self.id,
            'order_db_id': self.order_db_id,
            'payment_method': self.payment_method,
            'status': self.status,
            'transaction_id': self.transaction_id,
            'amount': self.amount,
            'paid_at': self.paid_at.isoformat() if self.paid_at else None,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self):
        return f'<Payment {self.payment_method} {self.status} ₹{self.amount}>'
