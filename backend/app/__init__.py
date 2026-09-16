"""Flask Application Factory."""
import os
from flask import Flask, send_from_directory
from app.config import config_by_name
from app.extensions import db, migrate, jwt, cors, socketio, ma, limiter


def create_app(config_name=None):
    """Create and configure the Flask application."""
    if config_name is None:
        config_name = os.getenv('FLASK_ENV', 'development')

    app = Flask(__name__, static_folder=None)
    app.config.from_object(config_by_name.get(config_name, config_by_name['default']))

    # Initialize extensions
    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)
    cors.init_app(app, resources={r"/api/*": {"origins": "*"}})
    socketio.init_app(app, cors_allowed_origins="*", async_mode='eventlet')
    ma.init_app(app)
    limiter.init_app(app)

    # Import and register blueprints
    from app.routes.auth import auth_bp
    from app.routes.menu import menu_bp
    from app.routes.cart import cart_bp
    from app.routes.orders import orders_bp
    from app.routes.payments import payments_bp
    from app.routes.admin import admin_bp
    from app.routes.notifications import notifications_bp
    from app.routes.analytics import analytics_bp
    from app.routes.chat import chat_bp

    app.register_blueprint(auth_bp)
    app.register_blueprint(menu_bp)
    app.register_blueprint(cart_bp)
    app.register_blueprint(orders_bp)
    app.register_blueprint(payments_bp)
    app.register_blueprint(admin_bp)
    app.register_blueprint(notifications_bp)
    app.register_blueprint(analytics_bp)
    app.register_blueprint(chat_bp)

    # Import socket events
    from app.sockets import events as _  # noqa: F841

    # Import models so they are registered
    from app.models import (  # noqa: F401
        User, Admin, Category, FoodItem,
        Cart, CartItem, Order, OrderItem,
        Payment, Token, Notification, Inventory,
        QRVerification, ChatRoom, ChatMessage,
    )

    # Serve uploaded files
    upload_dir = os.path.join(app.root_path, '..', app.config['UPLOAD_FOLDER'])
    os.makedirs(upload_dir, exist_ok=True)

    @app.route('/uploads/<path:filename>')
    def serve_upload(filename):
        return send_from_directory(upload_dir, filename)

    # Health check
    @app.route('/api/health')
    def health():
        return {'status': 'healthy', 'message': 'Smart Canteen API is running'}

    # Create tables
    with app.app_context():
        db.create_all()

    # JWT error handlers
    @jwt.expired_token_loader
    def expired_token_callback(jwt_header, jwt_payload):
        return {'error': 'Token has expired', 'code': 'token_expired'}, 401

    @jwt.invalid_token_loader
    def invalid_token_callback(error):
        return {'error': 'Invalid token', 'code': 'invalid_token'}, 401

    @jwt.unauthorized_loader
    def missing_token_callback(error):
        return {'error': 'Authorization required', 'code': 'authorization_required'}, 401

    return app
