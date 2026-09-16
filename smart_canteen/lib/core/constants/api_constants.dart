import 'package:flutter/foundation.dart';

class ApiConstants {
  // Configurable via UI/Storage. For now, we default to localhost/emulator IP
  // Android Emulator maps 10.0.2.2 to localhost. iOS simulator maps 127.0.0.1.
  // The system uses a dynamic IP config repository/provider.
  static String baseIp = kIsWeb ? 'localhost' : '10.0.2.2'; // default for Android Emulator. Switch to local PC IP when testing on physical devices
  static const int port = 5000;

  static String get baseUrl => 'http://$baseIp:$port';
  static String get wsUrl => 'http://$baseIp:$port';

  // Auth endpoints
  static const String login = '/api/auth/login';
  static const String adminLogin = '/api/auth/admin/login';
  static const String register = '/api/auth/register';
  static const String verifyOtp = '/api/auth/verify-otp';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password';
  static const String me = '/api/auth/me';
  static const String updateProfile = '/api/auth/profile';

  // Menu endpoints
  static const String categories = '/api/menu/categories';
  static const String foodItems = '/api/menu/food-items';
  static const String specials = '/api/menu/specials';
  static const String popular = '/api/menu/popular';
  static const String search = '/api/menu/search';

  // Cart endpoints
  static const String cart = '/api/cart';
  static const String cartItems = '/api/cart/items';

  // Order endpoints
  static const String orders = '/api/orders';
  static const String activeOrders = '/api/orders/active';

  // Payment endpoints
  static const String paymentPay = '/api/payments'; // /<order_id>/pay
  static const String receipt = '/api/payments'; // /<order_id>/receipt

  // Notification endpoints
  static const String notifications = '/api/notifications';
  static const String markNotificationRead = '/api/notifications'; // /<id>/read
  static const String markAllNotificationsRead = '/api/notifications/read-all';

  // Admin endpoints
  static const String adminDashboard = '/api/admin/dashboard';
  static const String adminMenu = '/api/admin/menu';
  static const String adminCategories = '/api/admin/categories';
  static const String adminOrders = '/api/admin/orders';
  static const String adminPendingOrders = '/api/admin/orders/pending';
  static const String verifyQr = '/api/admin/verify-qr';
  static const String adminUsers = '/api/admin/users';
  static const String adminInventory = '/api/admin/inventory';
}
