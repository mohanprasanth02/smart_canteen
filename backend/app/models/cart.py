"""Cart and CartItem models."""
from datetime import datetime, timezone
from app.extensions import db


class Cart(db.Model):
    __tablename__ = 'carts'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), unique=True, nullable=False, index=True)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = db.Column(
        db.DateTime,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    # Relationships
    items = db.relationship('CartItem', backref='cart', cascade='all, delete-orphan', lazy='joined')

    def to_dict(self):
        items_list = [item.to_dict() for item in self.items]
        subtotal = sum(item['total_price'] for item in items_list)
        tax = round(subtotal * 0.05, 2)  # 5% GST
        return {
            'id': self.id,
            'user_id': self.user_id,
            'items': items_list,
            'item_count': len(items_list),
            'subtotal': round(subtotal, 2),
            'tax': tax,
            'total': round(subtotal + tax, 2),
        }

    def __repr__(self):
        return f'<Cart user_id={self.user_id}>'


class CartItem(db.Model):
    __tablename__ = 'cart_items'

    id = db.Column(db.Integer, primary_key=True)
    cart_id = db.Column(db.Integer, db.ForeignKey('carts.id'), nullable=False, index=True)
    food_item_id = db.Column(db.Integer, db.ForeignKey('food_items.id'), nullable=False)
    quantity = db.Column(db.Integer, default=1, nullable=False)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    # Unique constraint: one food item per cart
    __table_args__ = (
        db.UniqueConstraint('cart_id', 'food_item_id', name='uq_cart_food_item'),
    )

    def to_dict(self):
        return {
            'id': self.id,
            'cart_id': self.cart_id,
            'food_item_id': self.food_item_id,
            'food_item': self.food_item.to_dict() if self.food_item else None,
            'quantity': self.quantity,
            'unit_price': self.food_item.price if self.food_item else 0,
            'total_price': round((self.food_item.price if self.food_item else 0) * self.quantity, 2),
        }

    def __repr__(self):
        return f'<CartItem cart={self.cart_id} food={self.food_item_id} qty={self.quantity}>'
