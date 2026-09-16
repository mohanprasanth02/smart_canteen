"""QR code helper utilities."""
import hashlib
import hmac
import json
from flask import current_app


def generate_qr_data(order_id: str, token_number: str, user_id: int) -> str:
    """Generate QR code data with HMAC verification hash.
    
    Returns JSON string containing order details and verification hash.
    """
    payload = {
        'order_id': order_id,
        'token_number': token_number,
        'user_id': user_id,
    }
    
    # Generate HMAC-SHA256 verification hash
    secret = current_app.config.get('QR_SECRET_KEY', 'default-qr-secret')
    message = f'{order_id}:{token_number}:{user_id}'
    verification_hash = hmac.new(
        secret.encode('utf-8'),
        message.encode('utf-8'),
        hashlib.sha256,
    ).hexdigest()
    
    payload['verification_hash'] = verification_hash
    
    return json.dumps(payload)


def verify_qr_data(qr_json: str) -> dict:
    """Verify QR code data integrity.
    
    Returns:
        dict with 'valid' (bool) and parsed payload, or error message.
    """
    try:
        payload = json.loads(qr_json)
    except (json.JSONDecodeError, TypeError):
        return {'valid': False, 'error': 'Invalid QR data format'}
    
    required_fields = ['order_id', 'token_number', 'user_id', 'verification_hash']
    for field in required_fields:
        if field not in payload:
            return {'valid': False, 'error': f'Missing field: {field}'}
    
    # Verify HMAC
    secret = current_app.config.get('QR_SECRET_KEY', 'default-qr-secret')
    message = f"{payload['order_id']}:{payload['token_number']}:{payload['user_id']}"
    expected_hash = hmac.new(
        secret.encode('utf-8'),
        message.encode('utf-8'),
        hashlib.sha256,
    ).hexdigest()
    
    if not hmac.compare_digest(payload['verification_hash'], expected_hash):
        return {'valid': False, 'error': 'QR verification failed - invalid hash'}
    
    return {
        'valid': True,
        'order_id': payload['order_id'],
        'token_number': payload['token_number'],
        'user_id': payload['user_id'],
        'verification_hash': payload['verification_hash'],
    }
