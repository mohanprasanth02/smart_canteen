"""Inventory model for raw material tracking."""
from datetime import datetime, timezone
from app.extensions import db


class Inventory(db.Model):
    __tablename__ = 'inventory'

    id = db.Column(db.Integer, primary_key=True)
    item_name = db.Column(db.String(200), unique=True, nullable=False, index=True)
    quantity = db.Column(db.Float, default=0, nullable=False)
    unit = db.Column(db.String(50), nullable=False)  # kg, liters, pieces, packets
    reorder_level = db.Column(db.Float, default=10, nullable=False)
    cost_per_unit = db.Column(db.Float, default=0, nullable=False)
    supplier = db.Column(db.String(200), nullable=True)
    last_restocked = db.Column(db.DateTime, nullable=True)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = db.Column(
        db.DateTime,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    @property
    def is_low_stock(self):
        return self.quantity <= self.reorder_level

    def to_dict(self):
        return {
            'id': self.id,
            'item_name': self.item_name,
            'quantity': self.quantity,
            'unit': self.unit,
            'reorder_level': self.reorder_level,
            'cost_per_unit': self.cost_per_unit,
            'supplier': self.supplier,
            'is_low_stock': self.is_low_stock,
            'last_restocked': self.last_restocked.isoformat() if self.last_restocked else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }

    def __repr__(self):
        return f'<Inventory {self.item_name} qty={self.quantity}{self.unit}>'
