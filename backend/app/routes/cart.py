"""Cart routes."""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.extensions import db
from app.models.cart import Cart, CartItem
from app.models.food_item import FoodItem

cart_bp = Blueprint('cart', __name__, url_prefix='/api/cart')


@cart_bp.route('', methods=['GET'])
@jwt_required()
def get_cart():
    """Get the current user's cart."""
    user_id = int(get_jwt_identity())
    cart = Cart.query.filter_by(user_id=user_id).first()

    if not cart:
        return jsonify({
            'id': None,
            'user_id': user_id,
            'items': [],
            'item_count': 0,
            'subtotal': 0,
            'tax': 0,
            'total': 0,
        }), 200

    return jsonify(cart.to_dict()), 200


@cart_bp.route('/items', methods=['POST'])
@jwt_required()
def add_to_cart():
    """Add an item to the cart."""
    user_id = int(get_jwt_identity())
    data = request.get_json()

    if not data or not data.get('food_item_id'):
        return jsonify({'error': 'food_item_id is required'}), 400

    food_item = FoodItem.query.get(data['food_item_id'])
    if not food_item:
        return jsonify({'error': 'Food item not found'}), 404

    if not food_item.is_available or food_item.quantity <= 0:
        return jsonify({'error': 'Food item is not available'}), 400

    quantity = data.get('quantity', 1)
    if quantity < 1:
        return jsonify({'error': 'Quantity must be at least 1'}), 400

    if quantity > food_item.quantity:
        return jsonify({'error': f'Only {food_item.quantity} available'}), 400

    # Get or create cart
    cart = Cart.query.filter_by(user_id=user_id).first()
    if not cart:
        cart = Cart(user_id=user_id)
        db.session.add(cart)
        db.session.flush()

    # Check if item already in cart
    existing = CartItem.query.filter_by(
        cart_id=cart.id,
        food_item_id=food_item.id,
    ).first()

    if existing:
        new_qty = existing.quantity + quantity
        if new_qty > food_item.quantity:
            return jsonify({'error': f'Only {food_item.quantity} available'}), 400
        existing.quantity = new_qty
    else:
        cart_item = CartItem(
            cart_id=cart.id,
            food_item_id=food_item.id,
            quantity=quantity,
        )
        db.session.add(cart_item)

    db.session.commit()

    return jsonify({
        'message': 'Item added to cart',
        'cart': cart.to_dict(),
    }), 200


@cart_bp.route('/items/<int:item_id>', methods=['PUT'])
@jwt_required()
def update_cart_item(item_id):
    """Update cart item quantity."""
    user_id = int(get_jwt_identity())
    data = request.get_json()

    if not data or 'quantity' not in data:
        return jsonify({'error': 'quantity is required'}), 400

    cart = Cart.query.filter_by(user_id=user_id).first()
    if not cart:
        return jsonify({'error': 'Cart not found'}), 404

    cart_item = CartItem.query.filter_by(
        id=item_id,
        cart_id=cart.id,
    ).first()
    if not cart_item:
        return jsonify({'error': 'Cart item not found'}), 404

    quantity = data['quantity']
    if quantity <= 0:
        db.session.delete(cart_item)
    else:
        if quantity > cart_item.food_item.quantity:
            return jsonify({'error': f'Only {cart_item.food_item.quantity} available'}), 400
        cart_item.quantity = quantity

    db.session.commit()

    return jsonify({
        'message': 'Cart updated',
        'cart': cart.to_dict(),
    }), 200


@cart_bp.route('/items/<int:item_id>', methods=['DELETE'])
@jwt_required()
def remove_from_cart(item_id):
    """Remove an item from the cart."""
    user_id = int(get_jwt_identity())
    cart = Cart.query.filter_by(user_id=user_id).first()
    if not cart:
        return jsonify({'error': 'Cart not found'}), 404

    cart_item = CartItem.query.filter_by(
        id=item_id,
        cart_id=cart.id,
    ).first()
    if not cart_item:
        return jsonify({'error': 'Cart item not found'}), 404

    db.session.delete(cart_item)
    db.session.commit()

    return jsonify({
        'message': 'Item removed from cart',
        'cart': cart.to_dict(),
    }), 200


@cart_bp.route('', methods=['DELETE'])
@jwt_required()
def clear_cart():
    """Clear all items from the cart."""
    user_id = int(get_jwt_identity())
    cart = Cart.query.filter_by(user_id=user_id).first()
    if cart:
        CartItem.query.filter_by(cart_id=cart.id).delete()
        db.session.commit()

    return jsonify({'message': 'Cart cleared'}), 200
