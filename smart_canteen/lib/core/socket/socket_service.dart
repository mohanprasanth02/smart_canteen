import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/api_constants.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  ref.onDispose(() => service.disconnect());
  return service;
});

class SocketService {
  io.Socket? _socket;
  final _connectionController = StreamController<bool>.broadcast();
  final _eventController = StreamController<SocketEvent>.broadcast();

  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<SocketEvent> get eventStream => _eventController.stream;
  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect({int? userId}) async {
    if (_socket != null && _socket!.connected) return;

    const storage = FlutterSecureStorage();
    final savedIp = await storage.read(key: 'server_ip');
    final wsUrl = savedIp != null && savedIp.isNotEmpty
        ? 'http://$savedIp:5000'
        : ApiConstants.wsUrl;

    _socket = io.io(
      wsUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setReconnectionAttempts(99)
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[SocketService] Connected to server');
      _connectionController.add(true);
      if (userId != null) {
        emitUserOnline(userId);
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint('[SocketService] Disconnected from server');
      _connectionController.add(false);
    });

    _socket!.onConnectError((err) {
      debugPrint('[SocketService] Connection error: $err');
      _connectionController.add(false);
    });

    // Listen to real-time events
    _socket!.on('menu_updated', (data) {
      _eventController.add(SocketEvent(type: 'menu_updated', data: data));
    });

    _socket!.on('stock_changed', (data) {
      _eventController.add(SocketEvent(type: 'stock_changed', data: data));
    });

    _socket!.on('order_created', (data) {
      _eventController.add(SocketEvent(type: 'order_created', data: data));
    });

    _socket!.on('order_status_changed', (data) {
      _eventController.add(SocketEvent(type: 'order_status_changed', data: data));
    });

    _socket!.on('payment_completed', (data) {
      _eventController.add(SocketEvent(type: 'payment_completed', data: data));
    });

    _socket!.on('token_verified', (data) {
      _eventController.add(SocketEvent(type: 'token_verified', data: data));
    });

    _socket!.on('user_connected', (data) {
      _eventController.add(SocketEvent(type: 'user_connected', data: data));
    });

    _socket!.on('user_disconnected', (data) {
      _eventController.add(SocketEvent(type: 'user_disconnected', data: data));
    });

    _socket!.on('inventory_alert', (data) {
      _eventController.add(SocketEvent(type: 'inventory_alert', data: data));
    });

    _socket!.on('notification_sent', (data) {
      _eventController.add(SocketEvent(type: 'notification_sent', data: data));
    });

    _socket!.on('new_chat_message', (data) {
      _eventController.add(SocketEvent(type: 'new_chat_message', data: data));
    });

    _socket!.on('chat_room_closed', (data) {
      _eventController.add(SocketEvent(type: 'chat_room_closed', data: data));
    });

    _socket!.on('kds_item_prepared', (data) {
      _eventController.add(SocketEvent(type: 'kds_item_prepared', data: data));
    });
  }

  io.Socket? get socket => _socket;

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _connectionController.add(false);
  }

  void joinRoom(String roomName) {
    _socket?.emit('join_room', {'room': roomName});
  }

  void leaveRoom(String roomName) {
    _socket?.emit('leave_room', {'room': roomName});
  }

  void emitUserOnline(int userId) {
    _socket?.emit('user_online', {'user_id': userId});
  }

  void emitUserOffline(int userId) {
    _socket?.emit('user_offline', {'user_id': userId});
  }
}

class SocketEvent {
  final String type;
  final dynamic data;

  SocketEvent({required this.type, required this.data});
}
