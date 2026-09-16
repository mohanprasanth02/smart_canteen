"""Menu routes for browsing food items."""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from app.extensions import db
from app.models.category import Category
from app.models.food_item import FoodItem

menu_bp = Blueprint('menu', __name__, url_prefix='/api/menu')


@menu_bp.route('/categories', methods=['GET'])
@jwt_required()
def get_categories():
    """Get all active food categories."""
    categories = Category.query.filter_by(is_active=True)\
        .order_by(Category.display_order).all()
    return jsonify({
        'categories': [c.to_dict() for c in categories],
    }), 200


@menu_bp.route('/categories/<int:category_id>', methods=['GET'])
@jwt_required()
def get_category(category_id):
    """Get a single category with its food items."""
    category = Category.query.get_or_404(category_id)
    items = FoodItem.query.filter_by(
        category_id=category_id,
        is_available=True,
    ).order_by(FoodItem.total_orders.desc()).all()

    return jsonify({
        'category': category.to_dict(),
        'items': [item.to_dict() for item in items],
    }), 200


@menu_bp.route('/food-items', methods=['GET'])
@jwt_required()
def get_food_items():
    """Get all food items with optional filtering."""
    query = FoodItem.query

    # Category filter
    category_id = request.args.get('category_id', type=int)
    if category_id:
        query = query.filter_by(category_id=category_id)

    # Veg filter
    is_veg = request.args.get('is_veg')
    if is_veg is not None:
        query = query.filter_by(is_veg=is_veg.lower() == 'true')

    # Available only
    available_only = request.args.get('available_only', 'true')
    if available_only.lower() == 'true':
        query = query.filter(FoodItem.is_available == True, FoodItem.quantity > 0)

    # Sort
    sort_by = request.args.get('sort_by', 'name')
    sort_order = request.args.get('sort_order', 'asc')
    
    sort_map = {
        'name': FoodItem.name,
        'price': FoodItem.price,
        'popularity': FoodItem.total_orders,
        'rating': FoodItem.rating,
        'created_at': FoodItem.created_at,
    }
    sort_col = sort_map.get(sort_by, FoodItem.name)
    if sort_order == 'desc':
        sort_col = sort_col.desc()
    query = query.order_by(sort_col)

    # Pagination
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 50, type=int)
    pagination = query.paginate(page=page, per_page=per_page, error_out=False)

    return jsonify({
        'items': [item.to_dict() for item in pagination.items],
        'total': pagination.total,
        'page': pagination.page,
        'pages': pagination.pages,
        'has_next': pagination.has_next,
    }), 200


@menu_bp.route('/food-items/<int:item_id>', methods=['GET'])
@jwt_required()
def get_food_item(item_id):
    """Get a single food item by ID."""
    item = FoodItem.query.get_or_404(item_id)
    return jsonify({'item': item.to_dict()}), 200


@menu_bp.route('/search', methods=['GET'])
@jwt_required()
def search_food():
    """Search food items by name or description."""
    query = request.args.get('q', '').strip()
    if not query or len(query) < 2:
        return jsonify({'items': [], 'query': query}), 200

    items = FoodItem.query.filter(
        db.or_(
            FoodItem.name.ilike(f'%{query}%'),
            FoodItem.description.ilike(f'%{query}%'),
        )
    ).filter_by(is_available=True).limit(20).all()

    return jsonify({
        'items': [item.to_dict() for item in items],
        'query': query,
        'count': len(items),
    }), 200


@menu_bp.route('/specials', methods=['GET'])
@jwt_required()
def get_specials():
    """Get today's special food items."""
    specials = FoodItem.query.filter_by(
        is_special=True,
        is_available=True,
    ).filter(FoodItem.quantity > 0).all()

    return jsonify({
        'specials': [item.to_dict() for item in specials],
    }), 200


@menu_bp.route('/popular', methods=['GET'])
@jwt_required()
def get_popular():
    """Get popular food items by total orders."""
    popular = FoodItem.query.filter_by(is_available=True)\
        .filter(FoodItem.quantity > 0)\
        .order_by(FoodItem.total_orders.desc())\
        .limit(10).all()

    return jsonify({
        'popular': [item.to_dict() for item in popular],
    }), 200
