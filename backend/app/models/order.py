"""Order and OrderItem models."""
from datetime import datetime, timezone
from app.extensions import db


class Order(db.Model):
    __tablename__ = 'orders'

    id = db.Column(db.Integer, primary_key=True)
    order_id = db.Column(db.String(20), unique=True, nullable=False, index=True)  # ORD-2026-000123
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    status = db.Column(
        db.String(20),
        default='placed',
        nullable=False,
        index=True,
    )  # placed, accepted, preparing, ready, completed, cancelled
    subtotal = db.Column(db.Float, nullable=False)
    tax = db.Column(db.Float, nullable=False)
    total_amount = db.Column(db.Float, nullable=False)
    pickup_time = db.Column(db.String(50), nullable=True)
    notes = db.Column(db.Text, nullable=True)
    cancel_reason = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = db.Column(
        db.DateTime,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    completed_at = db.Column(db.DateTime, nullable=True)

    # Relationships
    items = db.relationship('OrderItem', backref='order', cascade='all, delete-orphan', lazy='joined')
    payment = db.relationship('Payment', backref='order', uselist=False, cascade='all, delete-orphan')
    token = db.relationship('Token', backref='order', uselist=False, cascade='all, delete-orphan')
    qr_verifications = db.relationship('QRVerification', backref='order', cascade='all, delete-orphan')

    @staticmethod
    def generate_order_id():
        """Generate unique order ID like ORD-2026-000123."""
        now = datetime.now(timezone.utc)
        year = now.year
        last_order = Order.query.filter(
            Order.order_id.like(f'ORD-{year}-%')
        ).order_by(Order.id.desc()).first()
        
        if last_order:
            last_num = int(last_order.order_id.split('-')[-1])
            new_num = last_num + 1
        else:
            new_num = 1
        
        return f'ORD-{year}-{new_num:06d}'

    def to_dict(self):
        return {
            'id': self.id,
            'order_id': self.order_id,
            'user_id': self.user_id,
            'user': self.user.to_dict() if self.user else None,
            'status': self.status,
            'items': [item.to_dict() for item in self.items],
            'subtotal': self.subtotal,
            'tax': self.tax,
            'total_amount': self.total_amount,
            'pickup_time': self.pickup_time,
            'notes': self.notes,
            'cancel_reason': self.cancel_reason,
            'payment': self.payment.to_dict() if self.payment else None,
            'token': self.token.to_dict() if self.token else None,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'completed_at': self.completed_at.isoformat() if self.completed_at else None,
        }

    def to_summary_dict(self):
        """Lightweight dict for list views."""
        return {
            'id': self.id,
            'order_id': self.order_id,
            'status': self.status,
            'total_amount': self.total_amount,
            'item_count': len(self.items),
            'token_number': self.token.token_number if self.token else None,
            'payment_status': self.payment.status if self.payment else None,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self):
        return f'<Order {self.order_id} status={self.status}>'


class OrderItem(db.Model):
    __tablename__ = 'order_items'

    id = db.Column(db.Integer, primary_key=True)
    order_id = db.Column(db.Integer, db.ForeignKey('orders.id'), nullable=False, index=True)
    food_item_id = db.Column(db.Integer, db.ForeignKey('food_items.id'), nullable=False)
    food_name = db.Column(db.String(200), nullable=False)  # Snapshot at order time
    food_price = db.Column(db.Float, nullable=False)  # Snapshot at order time
    quantity = db.Column(db.Integer, nullable=False)
    total_price = db.Column(db.Float, nullable=False)
    counter_number = db.Column(db.Integer, default=1, nullable=False)
    is_prepared = db.Column(db.Boolean, default=False, nullable=False)

    def to_dict(self):
        return {
            'id': self.id,
            'food_item_id': self.food_item_id,
            'food_name': self.food_name,
            'food_price': self.food_price,
            'food_image': self.food_item.image if self.food_item else None,
            'quantity': self.quantity,
            'total_price': self.total_price,
            'counter_number': self.counter_number,
            'is_prepared': self.is_prepared,
        }

    def __repr__(self):
        return f'<OrderItem {self.food_name} x{self.quantity}>'
