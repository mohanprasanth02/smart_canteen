"""Entry point for the Smart Canteen backend server."""
import os
import socket
from app import create_app
from app.extensions import socketio


app = create_app()


def get_local_ip():
    """Get the local network IP address."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return '127.0.0.1'


if __name__ == '__main__':
    host = app.config.get('SERVER_HOST', '0.0.0.0')
    port = app.config.get('SERVER_PORT', 5000)
    local_ip = get_local_ip()

    print('=' * 60)
    print('  SMART CANTEEN MANAGEMENT SYSTEM')
    print('=' * 60)
    print(f'  Server running on:')
    print(f'    Local:   http://localhost:{port}')
    print(f'    Network: http://{local_ip}:{port}')
    print(f'')
    print(f'  Connect mobile devices to:')
    print(f'    http://{local_ip}:{port}')
    print(f'')
    print(f'  Health Check: http://{local_ip}:{port}/api/health')
    print('=' * 60)

    socketio.run(app, host=host, port=port, debug=True, allow_unsafe_werkzeug=True)
