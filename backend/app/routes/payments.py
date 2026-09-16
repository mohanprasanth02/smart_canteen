"""Payment routes."""
from datetime import datetime, timezone
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from app.extensions import db, socketio
from app.models.payment import Payment
from app.models.order import Order
import uuid

payments_bp = Blueprint('payments', __name__, url_prefix='/api/payments')


@payments_bp.route('/<order_id>/pay', methods=['POST'])
@jwt_required()
def process_payment(order_id):
    """Process payment for an order."""
    user_id = int(get_jwt_identity())
    data = request.get_json() or {}

    order = Order.query.filter_by(order_id=order_id).first()
    if not order:
        return jsonify({'error': 'Order not found'}), 404

    if order.user_id != user_id:
        return jsonify({'error': 'Access denied'}), 403

    payment = order.payment
    if not payment:
        return jsonify({'error': 'Payment record not found'}), 404

    if payment.status == 'paid':
        return jsonify({'error': 'Payment already completed'}), 400

    payment_method = data.get('payment_method', payment.payment_method)
    transaction_id = data.get('transaction_id', str(uuid.uuid4()))

    payment.payment_method = payment_method
    payment.status = 'paid'
    payment.transaction_id = transaction_id
    payment.paid_at = datetime.now(timezone.utc)

    db.session.commit()

    # Emit payment completed event
    socketio.emit('payment_completed', {
        'order_id': order.order_id,
        'user_id': user_id,
        'amount': payment.amount,
        'method': payment_method,
    }, namespace='/')

    return jsonify({
        'message': 'Payment successful',
        'payment': payment.to_dict(),
    }), 200


@payments_bp.route('/<order_id>', methods=['GET'])
@jwt_required()
def get_payment(order_id):
    """Get payment details for an order."""
    user_id = int(get_jwt_identity())
    claims = get_jwt()
    role = claims.get('role', 'student')

    order = Order.query.filter_by(order_id=order_id).first()
    if not order:
        return jsonify({'error': 'Order not found'}), 404

    if role == 'student' and order.user_id != user_id:
        return jsonify({'error': 'Access denied'}), 403

    if not order.payment:
        return jsonify({'error': 'No payment found'}), 404

    return jsonify({'payment': order.payment.to_dict()}), 200


@payments_bp.route('/<order_id>/receipt', methods=['GET'])
@jwt_required()
def get_receipt(order_id):
    """Generate payment receipt for an order."""
    user_id = int(get_jwt_identity())
    order = Order.query.filter_by(order_id=order_id).first()
    if not order:
        return jsonify({'error': 'Order not found'}), 404

    claims = get_jwt()
    role = claims.get('role', 'student')
    if role == 'student' and order.user_id != user_id:
        return jsonify({'error': 'Access denied'}), 403

    receipt = {
        'receipt_id': f'RCP-{order.order_id}',
        'order_id': order.order_id,
        'customer': order.user.full_name if order.user else 'Unknown',
        'items': [{
            'name': item.food_name,
            'qty': item.quantity,
            'price': item.food_price,
            'total': item.total_price,
        } for item in order.items],
        'subtotal': order.subtotal,
        'tax': order.tax,
        'total': order.total_amount,
        'payment_method': order.payment.payment_method if order.payment else 'N/A',
        'payment_status': order.payment.status if order.payment else 'N/A',
        'transaction_id': order.payment.transaction_id if order.payment else None,
        'token_number': order.token.token_number if order.token else 'N/A',
        'ordered_at': order.created_at.isoformat() if order.created_at else None,
        'paid_at': order.payment.paid_at.isoformat() if order.payment and order.payment.paid_at else None,
    }

    return jsonify({'receipt': receipt}), 200
