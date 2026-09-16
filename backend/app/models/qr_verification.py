"""QR Verification model."""
from datetime import datetime, timezone
from app.extensions import db


class QRVerification(db.Model):
    __tablename__ = 'qr_verifications'

    id = db.Column(db.Integer, primary_key=True)
    order_db_id = db.Column(db.Integer, db.ForeignKey('orders.id'), nullable=False, index=True)
    token_number = db.Column(db.String(20), nullable=False)
    verification_hash = db.Column(db.String(255), nullable=False)
    verified_by_admin_id = db.Column(db.Integer, db.ForeignKey('admins.id'), nullable=True)
    status = db.Column(db.String(20), default='verified', nullable=False)  # verified, failed, duplicate
    scanned_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    ip_address = db.Column(db.String(50), nullable=True)

    def to_dict(self):
        return {
            'id': self.id,
            'order_db_id': self.order_db_id,
            'token_number': self.token_number,
            'status': self.status,
            'verified_by': self.verified_by_admin.full_name if self.verified_by_admin else None,
            'scanned_at': self.scanned_at.isoformat() if self.scanned_at else None,
        }

    def __repr__(self):
        return f'<QRVerification order={self.order_db_id} status={self.status}>'
