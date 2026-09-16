"""Authentication routes."""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import (
    jwt_required, get_jwt_identity, get_jwt,
)
from app.extensions import db, limiter
from app.models.user import User
from app.models.admin import Admin
from app.utils.auth_helpers import (
    hash_password, verify_password, generate_tokens,
    generate_otp, get_otp_expiry, verify_otp,
)

auth_bp = Blueprint('auth', __name__, url_prefix='/api/auth')


@auth_bp.route('/register', methods=['POST'])
@limiter.limit("10 per minute")
def register():
    """Register a new student user."""
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body is required'}), 400

    required = ['full_name', 'register_number', 'department', 'year', 'mobile_number', 'email', 'password']
    missing = [f for f in required if not data.get(f)]
    if missing:
        return jsonify({'error': f'Missing fields: {", ".join(missing)}'}), 400

    # Check duplicates
    if User.query.filter_by(email=data['email']).first():
        return jsonify({'error': 'Email already registered'}), 409
    if User.query.filter_by(register_number=data['register_number']).first():
        return jsonify({'error': 'Register number already exists'}), 409
    if User.query.filter_by(mobile_number=data['mobile_number']).first():
        return jsonify({'error': 'Mobile number already registered'}), 409

    # Validate password
    if len(data['password']) < 6:
        return jsonify({'error': 'Password must be at least 6 characters'}), 400

    otp = generate_otp()
    user = User(
        full_name=data['full_name'],
        register_number=data['register_number'],
        department=data['department'],
        year=int(data['year']),
        mobile_number=data['mobile_number'],
        email=data['email'],
        password_hash=hash_password(data['password']),
        profile_photo=data.get('profile_photo'),
        otp_code=otp,
        otp_expires_at=get_otp_expiry(),
        is_verified=True,  # Auto-verify for local deployment
    )

    db.session.add(user)
    db.session.commit()

    # Log OTP to console for development
    print(f"[OTP] User {user.email}: {otp}")

    tokens = generate_tokens(
        identity=str(user.id),
        additional_claims={'role': 'student', 'name': user.full_name},
    )

    # Emit socket event for new registration
    from app.extensions import socketio
    socketio.emit('user_registered', {
        'user': user.to_dict(),
    }, namespace='/')

    return jsonify({
        'message': 'Registration successful',
        'user': user.to_dict(),
        **tokens,
    }), 201


@auth_bp.route('/login', methods=['POST'])
@limiter.limit("20 per minute")
def login():
    """Login for students."""
    data = request.get_json()
    if not data or not data.get('email') or not data.get('password'):
        return jsonify({'error': 'Email and password are required'}), 400

    user = User.query.filter_by(email=data['email']).first()
    if not user or not verify_password(data['password'], user.password_hash):
        return jsonify({'error': 'Invalid email or password'}), 401

    if not user.is_active:
        return jsonify({'error': 'Account has been suspended'}), 403

    tokens = generate_tokens(
        identity=str(user.id),
        additional_claims={'role': 'student', 'name': user.full_name},
    )

    return jsonify({
        'message': 'Login successful',
        'user': user.to_dict(),
        **tokens,
    }), 200


@auth_bp.route('/admin/login', methods=['POST'])
@limiter.limit("10 per minute")
def admin_login():
    """Login for admin users."""
    data = request.get_json()
    if not data or not data.get('username') or not data.get('password'):
        return jsonify({'error': 'Username and password are required'}), 400

    admin = Admin.query.filter_by(username=data['username']).first()
    if not admin or not verify_password(data['password'], admin.password_hash):
        return jsonify({'error': 'Invalid credentials'}), 401

    if not admin.is_active:
        return jsonify({'error': 'Admin account is disabled'}), 403

    tokens = generate_tokens(
        identity=str(admin.id),
        additional_claims={'role': admin.role, 'name': admin.full_name},
    )

    return jsonify({
        'message': 'Admin login successful',
        'admin': admin.to_dict(),
        **tokens,
    }), 200


@auth_bp.route('/verify-otp', methods=['POST'])
@limiter.limit("10 per minute")
def verify_otp_route():
    """Verify email OTP."""
    data = request.get_json()
    if not data or not data.get('email') or not data.get('otp'):
        return jsonify({'error': 'Email and OTP are required'}), 400

    user = User.query.filter_by(email=data['email']).first()
    if not user:
        return jsonify({'error': 'User not found'}), 404

    if not verify_otp(user.otp_code, data['otp'], user.otp_expires_at):
        return jsonify({'error': 'Invalid or expired OTP'}), 400

    user.is_verified = True
    user.otp_code = None
    user.otp_expires_at = None
    db.session.commit()

    return jsonify({'message': 'Email verified successfully'}), 200


@auth_bp.route('/forgot-password', methods=['POST'])
@limiter.limit("5 per minute")
def forgot_password():
    """Send password reset OTP."""
    data = request.get_json()
    if not data or not data.get('email'):
        return jsonify({'error': 'Email is required'}), 400

    user = User.query.filter_by(email=data['email']).first()
    if not user:
        return jsonify({'error': 'Email not found'}), 404

    otp = generate_otp()
    user.otp_code = otp
    user.otp_expires_at = get_otp_expiry()
    db.session.commit()

    print(f"[PASSWORD RESET OTP] User {user.email}: {otp}")

    return jsonify({'message': 'OTP sent to your email'}), 200


@auth_bp.route('/reset-password', methods=['POST'])
@limiter.limit("5 per minute")
def reset_password():
    """Reset password with OTP verification."""
    data = request.get_json()
    required = ['email', 'otp', 'new_password']
    if not data or not all(data.get(f) for f in required):
        return jsonify({'error': 'Email, OTP, and new password are required'}), 400

    user = User.query.filter_by(email=data['email']).first()
    if not user:
        return jsonify({'error': 'User not found'}), 404

    if not verify_otp(user.otp_code, data['otp'], user.otp_expires_at):
        return jsonify({'error': 'Invalid or expired OTP'}), 400

    if len(data['new_password']) < 6:
        return jsonify({'error': 'Password must be at least 6 characters'}), 400

    user.password_hash = hash_password(data['new_password'])
    user.otp_code = None
    user.otp_expires_at = None
    db.session.commit()

    return jsonify({'message': 'Password reset successful'}), 200


@auth_bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh():
    """Refresh access token."""
    identity = get_jwt_identity()
    claims = get_jwt()
    access_token = generate_tokens(
        identity=identity,
        additional_claims={'role': claims.get('role', 'student'), 'name': claims.get('name', '')},
    )['access_token']

    return jsonify({'access_token': access_token}), 200


@auth_bp.route('/me', methods=['GET'])
@jwt_required()
def get_current_user():
    """Get current user profile."""
    identity = get_jwt_identity()
    claims = get_jwt()
    role = claims.get('role', 'student')

    if role in ('admin', 'super_admin'):
        admin = Admin.query.get(int(identity))
        if not admin:
            return jsonify({'error': 'Admin not found'}), 404
        return jsonify({'user': admin.to_dict(), 'role': role}), 200
    else:
        user = User.query.get(int(identity))
        if not user:
            return jsonify({'error': 'User not found'}), 404
        return jsonify({'user': user.to_dict(), 'role': 'student'}), 200


@auth_bp.route('/profile', methods=['PUT'])
@jwt_required()
def update_profile():
    """Update user profile."""
    identity = get_jwt_identity()
    claims = get_jwt()

    if claims.get('role', 'student') != 'student':
        return jsonify({'error': 'Only students can update profile here'}), 403

    user = User.query.get(int(identity))
    if not user:
        return jsonify({'error': 'User not found'}), 404

    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body is required'}), 400

    updatable = ['full_name', 'department', 'year', 'mobile_number', 'profile_photo']
    for field in updatable:
        if field in data:
            setattr(user, field, data[field])

    db.session.commit()

    # Emit profile update
    from app.extensions import socketio
    socketio.emit('user_profile_updated', {
        'user': user.to_dict(),
    }, namespace='/')

    return jsonify({'message': 'Profile updated', 'user': user.to_dict()}), 200


@auth_bp.route('/fcm-token', methods=['POST'])
@jwt_required()
def update_fcm_token():
    """Save user FCM token for push notifications."""
    identity = get_jwt_identity()
    claims = get_jwt()
    role = claims.get('role', 'student')

    if role != 'student':
        return jsonify({'error': 'Only students can save FCM tokens'}), 403

    data = request.get_json()
    if not data or not data.get('fcm_token'):
        return jsonify({'error': 'FCM token is required'}), 400

    user = User.query.get(int(identity))
    if not user:
        return jsonify({'error': 'User not found'}), 404

    user.fcm_token = data['fcm_token']
    db.session.commit()

    return jsonify({'message': 'FCM token updated successfully'}), 200
