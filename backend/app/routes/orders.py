"""Order routes."""
from datetime import datetime, timezone
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from app.extensions import db, socketio
from app.models.cart import Cart, CartItem
from app.models.order import Order, OrderItem
from app.models.payment import Payment
from app.models.token import Token
from app.models.food_item import FoodItem
from app.models.notification import Notification
from app.utils.qr_helpers import generate_qr_data

orders_bp = Blueprint('orders', __name__, url_prefix='/api/orders')


@orders_bp.route('', methods=['POST'])
@jwt_required()
def create_order():
    """Create a new order from the user's cart."""
    user_id = int(get_jwt_identity())
    data = request.get_json() or {}

    cart = Cart.query.filter_by(user_id=user_id).first()
    if not cart or not cart.items:
        return jsonify({'error': 'Cart is empty'}), 400

    # Validate all items are still available
    for cart_item in cart.items:
        food = cart_item.food_item
        if not food.is_available or food.quantity < cart_item.quantity:
            return jsonify({
                'error': f'{food.name} is no longer available in requested quantity',
            }), 400

    # Calculate totals
    cart_dict = cart.to_dict()
    subtotal = cart_dict['subtotal']
    tax = cart_dict['tax']
    total = cart_dict['total']

    # Create order
    order = Order(
        order_id=Order.generate_order_id(),
        user_id=user_id,
        status='placed',
        subtotal=subtotal,
        tax=tax,
        total_amount=total,
        pickup_time=data.get('pickup_time'),
        notes=data.get('notes'),
    )
    db.session.add(order)
    db.session.flush()

    # Create order items and update stock
    for cart_item in cart.items:
        food = cart_item.food_item
        order_item = OrderItem(
            order_id=order.id,
            food_item_id=food.id,
            food_name=food.name,
            food_price=food.price,
            quantity=cart_item.quantity,
            total_price=round(food.price * cart_item.quantity, 2),
            counter_number=food.counter_number,
        )
        db.session.add(order_item)

        # Decrease stock
        food.quantity = max(0, food.quantity - cart_item.quantity)
        food.total_orders += cart_item.quantity
        if food.quantity == 0:
            food.is_available = False

    # Create payment record
    payment_method = data.get('payment_method', 'cash')
    payment = Payment(
        order_db_id=order.id,
        payment_method=payment_method,
        status='paid' if payment_method == 'cash' else 'pending',
        amount=total,
        transaction_id=data.get('transaction_id'),
        paid_at=datetime.now(timezone.utc) if payment_method == 'cash' else None,
    )
    db.session.add(payment)

    # Generate token
    token = Token(
        token_number=Token.generate_token_number(),
        order_db_id=order.id,
        user_id=user_id,
    )
    db.session.add(token)
    db.session.flush()

    # Generate QR data
    qr_data = generate_qr_data(order.order_id, token.token_number, user_id)
    token.qr_data = qr_data

    # Clear cart
    CartItem.query.filter_by(cart_id=cart.id).delete()

    # Create notification
    notif = Notification(
        user_id=user_id,
        title='Order Placed',
        message=f'Your order {order.order_id} has been placed. Token: {token.token_number}',
        type='order',
    )
    db.session.add(notif)

    db.session.commit()

    order_data = order.to_dict()

    # Emit real-time events
    socketio.emit('order_created', {'order': order_data}, namespace='/')
    socketio.emit('stock_changed', {
        'items': [{'id': ci.food_item_id, 'quantity': ci.food_item.quantity, 'is_available': ci.food_item.is_available} for ci in order.items],
    }, namespace='/')

    return jsonify({
        'message': 'Order placed successfully',
        'order': order_data,
    }), 201


@orders_bp.route('', methods=['GET'])
@jwt_required()
def get_orders():
    """Get orders for the current user."""
    user_id = int(get_jwt_identity())
    claims = get_jwt()
    role = claims.get('role', 'student')

    status = request.args.get('status')
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)

    if role in ('admin', 'super_admin'):
        query = Order.query
    else:
        query = Order.query.filter_by(user_id=user_id)

    if status:
        query = query.filter_by(status=status)

    pagination = query.order_by(Order.created_at.desc()).paginate(
        page=page, per_page=per_page, error_out=False,
    )

    return jsonify({
        'orders': [o.to_summary_dict() for o in pagination.items],
        'total': pagination.total,
        'page': pagination.page,
        'pages': pagination.pages,
    }), 200


@orders_bp.route('/<order_id>', methods=['GET'])
@jwt_required()
def get_order(order_id):
    """Get a single order by order_id string."""
    user_id = int(get_jwt_identity())
    claims = get_jwt()
    role = claims.get('role', 'student')

    order = Order.query.filter_by(order_id=order_id).first()
    if not order:
        return jsonify({'error': 'Order not found'}), 404

    # Students can only view their own orders
    if role == 'student' and order.user_id != user_id:
        return jsonify({'error': 'Access denied'}), 403

    return jsonify({'order': order.to_dict()}), 200


@orders_bp.route('/<order_id>/status', methods=['PUT'])
@jwt_required()
def update_order_status(order_id):
    """Update order status (admin only)."""
    claims = get_jwt()
    if claims.get('role') not in ('admin', 'super_admin'):
        return jsonify({'error': 'Admin access required'}), 403

    data = request.get_json()
    if not data or not data.get('status'):
        return jsonify({'error': 'Status is required'}), 400

    valid_statuses = ['placed', 'accepted', 'preparing', 'ready', 'completed', 'cancelled']
    new_status = data['status']
    if new_status not in valid_statuses:
        return jsonify({'error': f'Invalid status. Must be one of: {", ".join(valid_statuses)}'}), 400

    order = Order.query.filter_by(order_id=order_id).first()
    if not order:
        return jsonify({'error': 'Order not found'}), 404

    old_status = order.status
    order.status = new_status

    if new_status == 'completed':
        order.completed_at = datetime.now(timezone.utc)
    if new_status == 'cancelled':
        order.cancel_reason = data.get('reason', 'Cancelled by admin')
        # Restore stock
        for item in order.items:
            food = FoodItem.query.get(item.food_item_id)
            if food:
                food.quantity += item.quantity
                food.is_available = True

    # Create notification
    status_messages = {
        'accepted': f'Your order {order.order_id} has been accepted!',
        'preparing': f'Your order {order.order_id} is being prepared.',
        'ready': f'Your order {order.order_id} is READY! Token: {order.token.token_number if order.token else "N/A"}',
        'completed': f'Your order {order.order_id} has been completed. Thank you!',
        'cancelled': f'Your order {order.order_id} has been cancelled.',
    }

    if new_status in status_messages:
        from app.utils.notifications_service import send_push_notification
        send_push_notification(
            user=order.user,
            title=f'Order {new_status.capitalize()}',
            message=status_messages[new_status],
            data={'order_id': order.order_id, 'status': new_status}
        )
    else:
        db.session.commit()

    # Emit real-time events
    socketio.emit('order_status_changed', {
        'order_id': order.order_id,
        'old_status': old_status,
        'new_status': new_status,
        'user_id': order.user_id,
        'order': order.to_summary_dict(),
    }, namespace='/')

    return jsonify({
        'message': f'Order status updated to {new_status}',
        'order': order.to_dict(),
    }), 200


@orders_bp.route('/active', methods=['GET'])
@jwt_required()
def get_active_orders():
    """Get active orders for the current user."""
    user_id = int(get_jwt_identity())
    active_statuses = ['placed', 'accepted', 'preparing', 'ready']
    orders = Order.query.filter(
        Order.user_id == user_id,
        Order.status.in_(active_statuses),
    ).order_by(Order.created_at.desc()).all()

    return jsonify({
        'orders': [o.to_dict() for o in orders],
        'count': len(orders),
    }), 200
