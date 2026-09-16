"""Analytics routes."""
from datetime import datetime, timedelta, timezone
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt
from sqlalchemy import func, extract
from app.extensions import db
from app.models.order import Order, OrderItem
from app.models.food_item import FoodItem
from app.models.user import User

analytics_bp = Blueprint('analytics', __name__, url_prefix='/api/analytics')


def admin_check():
    claims = get_jwt()
    return claims.get('role') in ('admin', 'super_admin')


@analytics_bp.route('/daily', methods=['GET'])
@jwt_required()
def daily_sales():
    """Get daily sales report."""
    if not admin_check():
        return jsonify({'error': 'Admin access required'}), 403

    days = request.args.get('days', 7, type=int)
    end_date = datetime.now(timezone.utc).date()
    start_date = end_date - timedelta(days=days - 1)

    results = db.session.query(
        func.date(Order.created_at).label('date'),
        func.count(Order.id).label('orders'),
        func.coalesce(func.sum(Order.total_amount), 0).label('revenue'),
    ).filter(
        func.date(Order.created_at) >= start_date,
        Order.status != 'cancelled',
    ).group_by(func.date(Order.created_at)).order_by(func.date(Order.created_at)).all()

    data = [{
        'date': str(r.date),
        'orders': r.orders,
        'revenue': round(float(r.revenue), 2),
    } for r in results]

    return jsonify({'daily_sales': data, 'period_days': days}), 200


@analytics_bp.route('/weekly', methods=['GET'])
@jwt_required()
def weekly_sales():
    """Get weekly sales summary."""
    if not admin_check():
        return jsonify({'error': 'Admin access required'}), 403

    weeks = request.args.get('weeks', 4, type=int)
    end_date = datetime.now(timezone.utc).date()
    start_date = end_date - timedelta(weeks=weeks)

    results = db.session.query(
        func.date(Order.created_at).label('date'),
        func.count(Order.id).label('orders'),
        func.coalesce(func.sum(Order.total_amount), 0).label('revenue'),
    ).filter(
        func.date(Order.created_at) >= start_date,
        Order.status != 'cancelled',
    ).group_by(func.date(Order.created_at)).order_by(func.date(Order.created_at)).all()

    data = [{
        'date': str(r.date),
        'orders': r.orders,
        'revenue': round(float(r.revenue), 2),
    } for r in results]

    total_orders = sum(d['orders'] for d in data)
    total_revenue = sum(d['revenue'] for d in data)

    return jsonify({
        'weekly_sales': data,
        'total_orders': total_orders,
        'total_revenue': round(total_revenue, 2),
        'period_weeks': weeks,
    }), 200


@analytics_bp.route('/monthly', methods=['GET'])
@jwt_required()
def monthly_sales():
    """Get monthly sales summary."""
    if not admin_check():
        return jsonify({'error': 'Admin access required'}), 403

    months = request.args.get('months', 6, type=int)
    end_date = datetime.now(timezone.utc).date()
    start_date = end_date - timedelta(days=months * 30)

    results = db.session.query(
        extract('year', Order.created_at).label('year'),
        extract('month', Order.created_at).label('month'),
        func.count(Order.id).label('orders'),
        func.coalesce(func.sum(Order.total_amount), 0).label('revenue'),
    ).filter(
        func.date(Order.created_at) >= start_date,
        Order.status != 'cancelled',
    ).group_by('year', 'month').order_by('year', 'month').all()

    data = [{
        'year': int(r.year),
        'month': int(r.month),
        'orders': r.orders,
        'revenue': round(float(r.revenue), 2),
    } for r in results]

    return jsonify({'monthly_sales': data, 'period_months': months}), 200


@analytics_bp.route('/top-foods', methods=['GET'])
@jwt_required()
def top_foods():
    """Get top selling food items."""
    if not admin_check():
        return jsonify({'error': 'Admin access required'}), 403

    limit = request.args.get('limit', 10, type=int)

    items = FoodItem.query.order_by(FoodItem.total_orders.desc()).limit(limit).all()
    data = [{
        'id': item.id,
        'name': item.name,
        'category': item.category.name if item.category else 'Unknown',
        'price': item.price,
        'total_orders': item.total_orders,
        'revenue': round(item.price * item.total_orders, 2),
        'is_veg': item.is_veg,
    } for item in items]

    return jsonify({'top_foods': data}), 200


@analytics_bp.route('/peak-hours', methods=['GET'])
@jwt_required()
def peak_hours():
    """Get peak order hours."""
    if not admin_check():
        return jsonify({'error': 'Admin access required'}), 403

    results = db.session.query(
        extract('hour', Order.created_at).label('hour'),
        func.count(Order.id).label('orders'),
    ).filter(
        Order.status != 'cancelled',
    ).group_by('hour').order_by('hour').all()

    data = [{
        'hour': int(r.hour),
        'hour_label': f'{int(r.hour):02d}:00',
        'orders': r.orders,
    } for r in results]

    return jsonify({'peak_hours': data}), 200


@analytics_bp.route('/export/csv', methods=['GET'])
@jwt_required()
def export_csv():
    """Export sales data as CSV."""
    if not admin_check():
        return jsonify({'error': 'Admin access required'}), 403

    days = request.args.get('days', 30, type=int)
    end_date = datetime.now(timezone.utc).date()
    start_date = end_date - timedelta(days=days)

    orders = Order.query.filter(
        func.date(Order.created_at) >= start_date,
        Order.status != 'cancelled',
    ).order_by(Order.created_at).all()

    csv_lines = ['Order ID,Date,Items,Subtotal,Tax,Total,Payment Method,Status']
    for o in orders:
        items_str = '; '.join([f'{i.food_name} x{i.quantity}' for i in o.items])
        pay_method = o.payment.payment_method if o.payment else 'N/A'
        csv_lines.append(
            f'{o.order_id},{o.created_at.strftime("%Y-%m-%d %H:%M")},"{items_str}",{o.subtotal},{o.tax},{o.total_amount},{pay_method},{o.status}'
        )

    csv_content = '\n'.join(csv_lines)
    return jsonify({
        'csv': csv_content,
        'filename': f'sales_report_{start_date}_{end_date}.csv',
        'rows': len(orders),
    }), 200
