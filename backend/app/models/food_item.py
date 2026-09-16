"""FoodItem model."""
from datetime import datetime, timezone
from app.extensions import db


class FoodItem(db.Model):
    __tablename__ = 'food_items'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(200), nullable=False, index=True)
    description = db.Column(db.Text, nullable=True)
    price = db.Column(db.Float, nullable=False)
    image = db.Column(db.String(500), nullable=True)
    category_id = db.Column(db.Integer, db.ForeignKey('categories.id'), nullable=False, index=True)
    quantity = db.Column(db.Integer, default=0, nullable=False)
    preparation_time = db.Column(db.Integer, default=10, nullable=False)  # minutes
    is_veg = db.Column(db.Boolean, default=True, nullable=False)
    is_available = db.Column(db.Boolean, default=True, nullable=False)
    is_special = db.Column(db.Boolean, default=False, nullable=False)
    counter_number = db.Column(db.Integer, default=1, nullable=False)
    rating = db.Column(db.Float, default=0.0, nullable=False)
    total_orders = db.Column(db.Integer, default=0, nullable=False)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = db.Column(
        db.DateTime,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    # Relationships
    cart_items = db.relationship('CartItem', backref='food_item', cascade='all, delete-orphan')
    order_items = db.relationship('OrderItem', backref='food_item', lazy='dynamic')

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'price': self.price,
            'image': self.image,
            'category_id': self.category_id,
            'category_name': self.category.name if self.category else None,
            'quantity': self.quantity,
            'preparation_time': self.preparation_time,
            'is_veg': self.is_veg,
            'is_available': self.is_available and self.quantity > 0,
            'is_special': self.is_special,
            'counter_number': self.counter_number,
            'rating': self.rating,
            'total_orders': self.total_orders,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self):
        return f'<FoodItem {self.name} ₹{self.price}>'
