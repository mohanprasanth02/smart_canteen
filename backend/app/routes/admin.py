"""Admin routes for canteen management."""
import os
import uuid
from datetime import datetime, timezone
from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt, get_jwt_identity
from werkzeug.utils import secure_filename
from app.extensions import db, socketio
from app.models.food_item import FoodItem
from app.models.category import Category
from app.models.order import Order, OrderItem
from app.models.user import User
from app.models.inventory import Inventory
from app.models.notification import Notification
from app.models.token import Token
from app.models.qr_verification import QRVerification
from app.utils.qr_helpers import verify_qr_data

admin_bp = Blueprint('admin', __name__, url_prefix='/api/admin')

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}


def admin_required():
    """Check if current user is admin."""
    claims = get_jwt()
    if claims.get('role') not in ('admin', 'super_admin'):
        return False
    return True


def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


# ─── Menu Management ──────────────────────────────────────────

@admin_bp.route('/menu', methods=['GET'])
@jwt_required()
def get_all_menu_items():
    """Get all menu items (including unavailable)."""
    if not admin_required():
        return jsonify({'error': 'Admin access required'}), 403

    items = FoodItem.query.order_by(FoodItem.category_id, FoodItem.name).all()
    return jsonify({'items': [i.to_dict() for i in items]}), 200


@admin_bp.route('/menu', methods=['POST'])
@jwt_required()
def add_menu_item():
    """Add a new food item to the menu."""
    if not admin_required():
        return jsonify({'error': 'Admin access required'}), 403

    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body is required'}), 400

    required = ['name', 'price', 'category_id']
    missing = [f for f in required if not data.get(f)]
    if missing:
        return jsonify({'error': f'Missing fields: {", ".join(missing)}'}), 400

    category = Category.query.get(data['category_id'])
    if not category:
        return jsonify({'error': 'Category not found'}), 404

    item = FoodItem(
        name=data['name'],
        description=data.get('description', ''),
        price=float(data['price']),
        image=data.get('image'),
        category_id=data['category_id'],
        quantity=int(data.get('quantity', 0)),
        preparation_time=int(data.get('preparation_time', 10)),
        is_veg=data.get('is_veg', True),
        is_available=data.get('is_available', True),
        is_special=data.get('is_special', False),
    )
    db.session.add(item)
    db.session.commit()

    # Broadcast to all connected clients
    socketio.emit('menu_updated', {
        'action': 'added',
        'item': item.to_dict(),
    }, namespace='/')

    return jsonify({
        'message': 'Food item added',
        'item': item.to_dict(),
    }), 201


@admin_bp.route('/menu/<int:item_id>', methods=['PUT'])
@jwt_required()
def update_menu_item(item_id):
    """Update a food item."""
    if not admin_required():
        return jsonify({'error': 'Admin access required'}), 403

    item = FoodItem.query.get_or_404(item_id)
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body is required'}), 400

    updatable = [
        'name', 'description', 'price', 'image', 'category_id',
        'quantity', 'preparation_time', 'is_veg', 'is_available', 'is_special',
    ]
    for field in updatable:
        if field in data:
            value = data[field]
            if field == 'price':
                value = float(value)
            elif field in ('quantity', 'preparation_time', 'category_id'):
                value = int(value)
            setattr(item, field, value)

    db.session.commit()

    # Broadcast update
    socketio.emit('menu_updated', {
        'action': 'updated',
        'item': item.to_dict(),
    }, namespace='/')

    return jsonify({
        'message': 'Food item updated',
        'item': item.to_dict(),
    }), 200


@admin_bp.route('/menu/<int:item_id>', methods=['DELETE'])
@jwt_required()
def delete_menu_item(item_id):
    """Delete a food item."""
    if not admin_required():
        return jsonify({'error': 'Admin access required'}), 403

    item = FoodItem.query.get_or_404(item_id)
    item_dict = item.to_dict()
    db.session.delete(item)
    db.session.commit()

    socketio.emit('menu_updated', {
        'action': 'deleted',
        'item': item_dict,
    }, namespace='/')

    return jsonify({'message': 'Food item deleted'}), 200


@admin_bp.route('/menu/<int:item_id>/stock', methods=['PUT'])
@jwt_required()
def update_stock(item_id):
    """Update food item stock."""
    if not admin_required():
        return jsonify({'error': 'Admin access required'}), 403

    item = FoodItem.query.get_or_404(item_id)
    data = request.get_json()
    if not data or 'quantity' not in data:
        return jsonify({'error': 'quantity is required'}), 400

    item.quantity = int(data['quantity'])
    item.is_available = item.quantity > 0
    db.session.commit()

    socketio.emit('stock_changed', {
        'items': [{'id': item.id, 'quantity': item.quantity, 'is_available': item.is_available}],
    }, namespace='/')

    return jsonify({
        'message': 'Stock updated',
        'item': item.to_dict(),
    }), 200


@admin_bp.route('/menu/upload-image', methods=['POST'])
@jwt_required()
def upload_image():
    """Upload a food item image."""
    if not admin_required():
        return jsonify({'error': 'Admin access required'}), 403

    if 'image' not in request.files:
        return jsonify({'error': 'No image file provided'}), 400

    file = request.files['image']
    if file.filename == '':
        return jsonify({'error': 'No file selected'}), 400

    if not allowed_file(file.filename):
        return jsonify({'error': 'File type not allowed'}), 400

    filename = f"{uuid.uuid4().hex}_{secure_filename(file.filename)}"
    upload_dir = os.path.join(current_app.root_path, '..', current_app.config['UPLOAD_FOLDER'])
    os.makedirs(upload_dir, exist_ok=True)
    filepath = os.path.join(upload_dir, filename)
    file.save(filepath)

    return jsonify({
        'message': 'Image uploaded',
        'filename': filename,
        'url': f'/uploads/{filename}',
    }), 200


# ─── Category Management ─────────────────────────────────────

@admin_bp.route('/categories', methods=['POST'])
@jwt_required()
def add_category():
    """Add a new category."""
    if not admin_required():
        return jsonify({'error': 'Admin access required'}), 403

    data = request.get_json()
    if not data or not data.get('name'):
        return jsonify({'error': 'Category name is required'}), 400

    if Category.query.filter_by(name=data['name']).first():
        return jsonify({'error': 'Category already exists'}), 409

    category = Category(
        name=data['name'],
        description=data.get('description'),
        image=data.get('image'),
        display_order=data.get('display_order', 0),
    )
    db.session.add(category)
    db.session.commit()

    return jsonify({
        'message': 'Category added',
        'category': category.to_dict(),
    }), 201


# ─── Order Management ────────────────────────────────────────

@admin_bp.route('/orders', methods=['GET'])
@jwt_required()
def get_all_orders():
    """Get all orders with filters."""
    if not admin_required():
        return jsonify({'error': 'Admin access required'}), 403

    status = request.args.get('status')
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 50, type=int)

    query = Order.query
    if status:
        query = query.filter_by(status=status)

    pagination = query.order_by(Order.created_at.desc()).paginate(
        page=page, per_page=per_page, error_out=False,
    )

    return jsonify({
        'orders': [o.to_dict() for o in pagination.items],
        'total': pagination.total,
        'page': pagination.page,
        'pages': pagination.pages,
    }), 200


@admin_bp.route('/orders/pending', methods=['GET'])
@jwt_required()
def get_pending_orders():
    """Get pending/active orders."""
    if not admin_required():
        return jsonify({'error': 'Admin access required'}), 403

    active_statuses = ['placed', 'accepted', 'preparing', 'ready']
    orders = Order.query.filter(
        Order.status.in_(active_statuses),
    ).order_by(Order.created_at.asc()).all()

    return jsonify({
        'orders': [o.to_dict() for o in orders],
        'count': len(orders),
    }), 200


# ─── QR Verification ─────────────────────────────────────────

@admin_bp.route('/verify-qr', methods=['POST'])
@jwt_required()
def verify_qr():
    """Verify a QR code and mark order as collected."""
    if not admin_required():
        return jsonify({'error': 'Admin access required'}), 403

    admin_id = int(get_jwt_identity())
    data = request.get_json()
    if not data or not data.get('qr_data'):
        return jsonify({'error': 'QR data is required'}), 400

    # Verify QR integrity
    result = verify_qr_data(data['qr_data'])
    if not result['valid']:
        return jsonify({'error': result['error']}), 400

    # Find order
    order = Order.query.filter_by(order_id=result['order_id']).first()
    if not order:
        return jsonify({'error': 'Order not found'}), 404

    # Find token
    token = order.token
    if not token:
        return jsonify({'error': 'Token not found for this order'}), 404

    # Check if already used
    if token.is_used:
        # Log duplicate attempt
        dup_verify = QRVerification(
            order_db_id=order.id,
            token_number=token.token_number,
            verification_hash=result['verification_hash'],
            verified_by_admin_id=admin_id,
            status='duplicate',
            ip_address=request.remote_addr,
        )
        db.session.add(dup_verify)
        db.session.commit()
        return jsonify({'error': 'Token has already been used', 'status': 'duplicate'}), 400

    # Check payment status
    if order.payment and order.payment.status != 'paid':
        return jsonify({'error': 'Payment not completed for this order'}), 400

    # Check order status
    if order.status not in ('accepted', 'preparing', 'ready'):
        return jsonify({
            'error': f'Order cannot be collected. Current status: {order.status}',
        }), 400

    # Mark token as used
    token.is_used = True
    token.used_at = datetime.now(timezone.utc)

    # Update order status
    order.status = 'completed'
    order.completed_at = datetime.now(timezone.utc)

    # Record verification
    verification = QRVerification(
        order_db_id=order.id,
        token_number=token.token_number,
        verification_hash=result['verification_hash'],
        verified_by_admin_id=admin_id,
        status='verified',
        ip_address=request.remote_addr,
    )
    db.session.add(verification)

    # Notify student
    from app.utils.notifications_service import send_push_notification
    send_push_notification(
        user=order.user,
        title='Order Collected',
        message=f'Your order {order.order_id} has been collected. Enjoy your meal!',
        data={'order_id': order.order_id, 'status': 'completed'}
    )

    # Emit events
    socketio.emit('token_verified', {
        'order_id': order.order_id,
        'token_number': token.token_number,
        'user_id': order.user_id,
    }, namespace='/')
    socketio.emit('order_status_changed', {
        'order_id': order.order_id,
        'old_status': 'ready',
        'new_status': 'completed',
        'user_id': order.user_id,
        'order': order.to_summary_dict(),
    }, namespace='/')

    return jsonify({
        'message': 'Order verified and marked as collected',
        'order': order.to_dict(),
        'verification': verification.to_dict(),
    }), 200


# ─── User Management ─────────────────────────────────────────

@admin_bp.route('/users', methods=['GET'])
@jwt_required()
def get_users():
    """Get all registered users."""
    if not admin_required():
        return jsonify({'error': 'Admin access required'}), 403

    search = request.args.get('search', '').strip()
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 50, type=int)

    query = User.query
    if search:
        query = query.filter(
            db.or_(
                User.full_name.ilike(f'%{search}%'),
                User.register_number.ilike(f'%{search}%'),
                User.email.ilike(f'%{search}%'),
            )
        )

    pagination = query.order_by(User.created_at.desc()).paginate(
        page=page, per_page=per_page, error_out=False,
    )

    return jsonify({
        'users': [u.to_dict() for u in pagination.items],
        'total': pagination.total,
        'page': pagination.page,
    }), 200


@admin_bp.route('/users/<int:user_id>/toggle', methods=['PUT'])
@jwt_required()
def toggle_user(user_id):
    """Suspend or activate a user."""
    if not admin_required():
        return jsonify({'error': 'Admin access required'}), 403

    user = User.query.get_or_404(user_id)
    user.is_active = not user.is_active
    db.session.commit()

    status = 'activated' if user.is_active else 'suspended'
    return jsonify({
        'message': f'User {status}',
        'user': user.to_dict(),
    }), 200


# ─── Inventory Management ────────────────────────────────────

@admin_bp.route('/inventory', methods=['GET'])
@jwt_required()
def get_inventory():
    """Get all inventory items."""
    if not admin_required():
        return jsonify({'error': 'Admin access required'}), 403

    items = Inventory.query.order_by(Inventory.item_name).all()
    low_stock = [i for i in items if i.is_low_stock]

    return jsonify({
        'items': [i.to_dict() for i in items],
        'total': len(items),
        'low_stock_count': len(low_stock),
        'low_stock_items': [i.to_dict() for i in low_stock],
    }), 200


@admin_bp.route('/inventory', methods=['POST'])
@jwt_required()
def add_inventory():
    """Add a new inventory item."""
    if not admin_required():
        return jsonify({'error': 'Admin access required'}), 403

    data = request.get_json()
    required = ['item_name', 'quantity', 'unit']
    missing = [f for f in required if not data.get(f)]
    if missing:
        return jsonify({'error': f'Missing: {", ".join(missing)}'}), 400

    if Inventory.query.filter_by(item_name=data['item_name']).first():
        return jsonify({'error': 'Inventory item already exists'}), 409

    item = Inventory(
        item_name=data['item_name'],
        quantity=float(data['quantity']),
        unit=data['unit'],
        reorder_level=float(data.get('reorder_level', 10)),
        cost_per_unit=float(data.get('cost_per_unit', 0)),
        supplier=data.get('supplier'),
        last_restocked=datetime.now(timezone.utc),
    )
    db.session.add(item)
    db.session.commit()

    return jsonify({
        'message': 'Inventory item added',
        'item': item.to_dict(),
    }), 201


@admin_bp.route('/inventory/<int:item_id>', methods=['PUT'])
@jwt_required()
def update_inventory(item_id):
    """Update an inventory item."""
    if not admin_required():
        return jsonify({'error': 'Admin access required'}), 403

    item = Inventory.query.get_or_404(item_id)
    data = request.get_json()

    old_qty = item.quantity
    updatable = ['item_name', 'quantity', 'unit', 'reorder_level', 'cost_per_unit', 'supplier']
    for field in updatable:
        if field in data:
            setattr(item, field, data[field])

    if 'quantity' in data and float(data['quantity']) > old_qty:
        item.last_restocked = datetime.now(timezone.utc)

    db.session.commit()

    # Alert if low stock
    if item.is_low_stock:
        socketio.emit('inventory_alert', {
            'item': item.to_dict(),
            'message': f'Low stock alert: {item.item_name} ({item.quantity} {item.unit} remaining)',
        }, namespace='/')

    return jsonify({
        'message': 'Inventory updated',
        'item': item.to_dict(),
    }), 200


# ─── Dashboard Stats ─────────────────────────────────────────

@admin_bp.route('/dashboard', methods=['GET'])
@jwt_required()
def get_dashboard():
    """Get admin dashboard statistics."""
    if not admin_required():
        return jsonify({'error': 'Admin access required'}), 403

    from sqlalchemy import func
    today = datetime.now(timezone.utc).date()

    total_users = User.query.count()
    total_orders = Order.query.count()
    orders_today = Order.query.filter(
        func.date(Order.created_at) == today
    ).count()
    pending_orders = Order.query.filter(
        Order.status.in_(['placed', 'accepted', 'preparing']),
    ).count()
    revenue_today = db.session.query(func.coalesce(func.sum(Order.total_amount), 0)).filter(
        func.date(Order.created_at) == today,
        Order.status != 'cancelled',
    ).scalar()
    total_revenue = db.session.query(func.coalesce(func.sum(Order.total_amount), 0)).filter(
        Order.status != 'cancelled',
    ).scalar()

    # Popular foods today
    popular = db.session.query(
        FoodItem.name,
        func.sum(OrderItem.quantity).label('total_qty'),
    ).join(
        OrderItem,
        FoodItem.id == OrderItem.food_item_id,
    ).group_by(FoodItem.name).order_by(db.desc('total_qty')).limit(5).all()

    popular_foods = [{'name': p[0], 'total_orders': int(p[1] or 0)} for p in popular] if popular else []

    # Low stock inventory
    low_stock = Inventory.query.filter(
        Inventory.quantity <= Inventory.reorder_level
    ).count()

    return jsonify({
        'total_users': total_users,
        'total_orders': total_orders,
        'orders_today': orders_today,
        'pending_orders': pending_orders,
        'revenue_today': round(float(revenue_today), 2),
        'total_revenue': round(float(total_revenue), 2),
        'popular_foods': popular_foods,
        'low_stock_alerts': low_stock,
    }), 200


@admin_bp.route('/kds/orders', methods=['GET'])
@jwt_required()
def get_kds_orders():
    """Get active orders filtered by counter for KDS."""
    if not admin_required():
        return jsonify({'error': 'Admin access required'}), 403

    counter = request.args.get('counter', type=int)

    # Active states
    active_states = ['placed', 'accepted', 'preparing']
    query = Order.query.filter(Order.status.in_(active_states))

    orders = query.order_by(Order.created_at.asc()).all()

    kds_orders = []
    for order in orders:
        # Filter items of the order that belong to this counter
        if counter:
            filtered_items = [item.to_dict() for item in order.items if item.counter_number == counter]
        else:
            filtered_items = [item.to_dict() for item in order.items]

        if filtered_items:
            order_dict = order.to_dict()
            # Replace items list with the filtered one for this KDS view
            order_dict['items'] = filtered_items
            kds_orders.append(order_dict)

    return jsonify({'orders': kds_orders}), 200


@admin_bp.route('/kds/items/<int:item_id>/prepare', methods=['POST'])
@jwt_required()
def prepare_kds_item(item_id):
    """Mark a specific order item as prepared in KDS."""
    if not admin_required():
        return jsonify({'error': 'Admin access required'}), 403

    order_item = OrderItem.query.get(item_id)
    if not order_item:
        return jsonify({'error': 'Order item not found'}), 404

    order = order_item.order
    if not order:
        return jsonify({'error': 'Associated order not found'}), 404

    if order_item.is_prepared:
        return jsonify({'message': 'Item already prepared', 'order': order.to_dict()}), 200

    order_item.is_prepared = True
    db.session.flush()

    old_status = order.status
    all_prepared = all(item.is_prepared for item in order.items)

    if all_prepared:
        order.status = 'ready'
        db.session.commit()

        # Notify student
        from app.utils.notifications_service import send_push_notification
        send_push_notification(
            user=order.user,
            title='Order Ready!',
            message=f'Your order {order.order_id} is ready for collection! Token: {order.token.token_number if order.token else "N/A"}',
            data={'order_id': order.order_id, 'status': 'ready'}
        )
    else:
        if order.status in ('placed', 'accepted'):
            order.status = 'preparing'
        db.session.commit()

    # Emit socket updates
    socketio.emit('kds_item_prepared', {
        'order_id': order.order_id,
        'item_id': order_item.id,
        'food_name': order_item.food_name,
        'counter_number': order_item.counter_number,
        'all_prepared': all_prepared
    }, namespace='/')

    if order.status != old_status:
        socketio.emit('order_status_changed', {
            'order_id': order.order_id,
            'old_status': old_status,
            'new_status': order.status,
            'user_id': order.user_id,
            'order': order.to_summary_dict(),
        }, namespace='/')

    return jsonify({
        'message': 'Item marked as prepared',
        'item': order_item.to_dict(),
        'order_status': order.status,
        'all_prepared': all_prepared
    }), 200
