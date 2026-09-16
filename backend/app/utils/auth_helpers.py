"""Authentication helper utilities."""
import hashlib
import random
import string
from datetime import datetime, timedelta, timezone

import bcrypt
from flask_jwt_extended import create_access_token, create_refresh_token


def hash_password(password: str) -> str:
    """Hash a password using bcrypt."""
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')


def verify_password(password: str, password_hash: str) -> bool:
    """Verify a password against its bcrypt hash."""
    return bcrypt.checkpw(password.encode('utf-8'), password_hash.encode('utf-8'))


def generate_tokens(identity: str, additional_claims: dict = None) -> dict:
    """Generate JWT access and refresh tokens."""
    access_token = create_access_token(
        identity=identity,
        additional_claims=additional_claims or {},
    )
    refresh_token = create_refresh_token(
        identity=identity,
        additional_claims=additional_claims or {},
    )
    return {
        'access_token': access_token,
        'refresh_token': refresh_token,
    }


def generate_otp() -> str:
    """Generate a 6-digit OTP code."""
    return ''.join(random.choices(string.digits, k=6))


def get_otp_expiry(minutes: int = 10) -> datetime:
    """Get OTP expiry datetime."""
    return datetime.now(timezone.utc) + timedelta(minutes=minutes)


def verify_otp(stored_otp: str, provided_otp: str, expires_at: datetime) -> bool:
    """Verify OTP code and check expiry."""
    if not stored_otp or not provided_otp:
        return False
    if datetime.now(timezone.utc) > expires_at:
        return False
    return stored_otp == provided_otp
