import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth_provider.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/home/presentation/home_screen.dart';
import 'package:smart_canteen/features/menu/presentation/menu_screen.dart';
import '../features/menu/presentation/food_detail_screen.dart';
import '../features/cart/presentation/cart_screen.dart';
import '../features/orders/presentation/orders_screen.dart';
import '../features/orders/presentation/order_detail_screen.dart';
import '../features/orders/presentation/order_tracking_screen.dart';
import '../features/qr/presentation/qr_display_screen.dart';
import '../features/qr/presentation/qr_scanner_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';

import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/admin/presentation/menu_management_screen.dart';
import '../features/admin/presentation/order_management_screen.dart';
import '../features/admin/presentation/inventory_screen.dart';
import '../features/admin/presentation/user_management_screen.dart';
import '../features/admin/presentation/analytics_screen.dart';
import '../features/admin/presentation/admin_chat_hub_screen.dart';
import '../features/admin/presentation/kds_screen.dart';
import '../features/chat/presentation/support_chat_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = authState.isAuthenticated;
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToRegister = state.matchedLocation == '/register';
      final isGoingToSplash = state.matchedLocation == '/splash';

      if (isGoingToSplash) return null;

      if (!isLoggedIn) {
        if (isGoingToLogin || isGoingToRegister) return null;
        return '/login';
      }

      if (isLoggedIn && (isGoingToLogin || isGoingToRegister)) {
        if (authState.role == 'student') {
          return '/home';
        } else {
          return '/admin-dashboard';
        }
      }

      // Check admin routes access
      final isAdminRoute = state.matchedLocation.startsWith('/admin') ||
          state.matchedLocation == '/qr-scanner';
      if (isAdminRoute && authState.role == 'student') {
        return '/home';
      }

      return null;
    },
    routes: [
      // Splash
      GoRoute(path: '/splash', pageBuilder: (context, state) => _fade(state, const SplashScreen())),

      // Auth
      GoRoute(path: '/login', pageBuilder: (context, state) => _slide(state, const LoginScreen())),
      GoRoute(path: '/register', pageBuilder: (context, state) => _slide(state, const RegisterScreen())),

      // Student Home/Core
      GoRoute(path: '/home', pageBuilder: (context, state) => _fade(state, const HomeScreen())),
      GoRoute(path: '/menu', pageBuilder: (context, state) => _slide(state, const MenuScreen())),
      GoRoute(
        path: '/food-detail',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return _slideUp(state, FoodDetailScreen(foodItem: extra['item']));
        },
      ),
      GoRoute(path: '/cart', pageBuilder: (context, state) => _slide(state, const CartScreen())),
      GoRoute(path: '/orders', pageBuilder: (context, state) => _slide(state, const OrdersScreen())),
      GoRoute(
        path: '/order-detail/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _slide(state, OrderDetailScreen(orderId: id));
        },
      ),
      GoRoute(
        path: '/order-tracking/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _slide(state, OrderTrackingScreen(orderId: id));
        },
      ),
      GoRoute(
        path: '/qr-display',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return _slideUp(state, QrDisplayScreen(
            orderId: extra['order_id'],
            tokenNumber: extra['token_number'],
            qrData: extra['qr_data'],
          ));
        },
      ),
      GoRoute(path: '/profile', pageBuilder: (context, state) => _slide(state, const ProfileScreen())),
      GoRoute(path: '/notifications', pageBuilder: (context, state) => _slide(state, const NotificationsScreen())),
      GoRoute(
        path: '/support-chat',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return _slideUp(state, SupportChatScreen(
            orderId: extra?['order_id'],
            orderCode: extra?['order_code'],
          ));
        },
      ),

      // Admin Panel
      GoRoute(path: '/admin-dashboard', pageBuilder: (context, state) => _fade(state, const AdminDashboardScreen())),
      GoRoute(path: '/admin-orders', pageBuilder: (context, state) => _slide(state, const OrderManagementScreen())),
      GoRoute(path: '/admin-menu', pageBuilder: (context, state) => _slide(state, const MenuManagementScreen())),
      GoRoute(path: '/admin-inventory', pageBuilder: (context, state) => _slide(state, const InventoryScreen())),
      GoRoute(path: '/admin-users', pageBuilder: (context, state) => _slide(state, const UserManagementScreen())),
      GoRoute(path: '/admin-analytics', pageBuilder: (context, state) => _slide(state, const AnalyticsScreen())),
      GoRoute(path: '/admin-chat-hub', pageBuilder: (context, state) => _slideUp(state, const AdminChatHubScreen())),
      GoRoute(path: '/admin-kds', pageBuilder: (context, state) => _slide(state, const KdsScreen())),
      GoRoute(path: '/qr-scanner', pageBuilder: (context, state) => _slideUp(state, const QrScannerScreen())),
    ],
  );
});

// ─── Transition helpers ───────────────────────────────────────
CustomTransitionPage<void> _fade(GoRouterState s, Widget child) =>
    CustomTransitionPage<void>(
      key: s.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, anim, __, c) => FadeTransition(opacity: anim, child: c),
    );

CustomTransitionPage<void> _slide(GoRouterState s, Widget child) =>
    CustomTransitionPage<void>(
      key: s.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 320),
      transitionsBuilder: (_, anim, __, c) {
        final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: anim.drive(tween), child: c);
      },
    );

CustomTransitionPage<void> _slideUp(GoRouterState s, Widget child) =>
    CustomTransitionPage<void>(
      key: s.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (_, anim, __, c) {
        final tween = Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: anim.drive(tween), child: FadeTransition(opacity: anim, child: c));
      },
    );
