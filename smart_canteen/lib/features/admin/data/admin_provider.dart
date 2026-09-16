import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/socket/socket_service.dart';
import '../../auth/data/auth_provider.dart';
import 'admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(apiClientProvider));
});

// Live Stats Provider
final adminStatsProvider = StateNotifierProvider<AdminStatsNotifier, AsyncValue<Map<String, dynamic>>>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  final socketService = ref.watch(socketServiceProvider);
  return AdminStatsNotifier(repo, socketService);
});

class AdminStatsNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final AdminRepository _repo;
  final SocketService _socketService;

  AdminStatsNotifier(this._repo, this._socketService) : super(const AsyncValue.loading()) {
    loadStats();
    _listenToSocket();
  }

  Future<void> loadStats() async {
    try {
      final stats = await _repo.getDashboardStats();
      state = AsyncValue.data(stats);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _listenToSocket() {
    _socketService.eventStream.listen((event) {
      if (!mounted) return;

      // Realtime count modifications on event triggers
      if (event.type == 'order_created' || 
          event.type == 'order_status_changed' || 
          event.type == 'user_connected' ||
          event.type == 'user_disconnected' ||
          event.type == 'payment_completed' ||
          event.type == 'token_verified') {
        loadStats();
      }
    });
  }
}

// Live Admin Order Feed
final adminOrdersProvider = StateNotifierProvider<AdminOrdersNotifier, AsyncValue<List<dynamic>>>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  final socketService = ref.watch(socketServiceProvider);
  return AdminOrdersNotifier(repo, socketService);
});

class AdminOrdersNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  final AdminRepository _repo;
  final SocketService _socketService;

  AdminOrdersNotifier(this._repo, this._socketService) : super(const AsyncValue.loading()) {
    loadOrders();
    _listenToSocket();
  }

  Future<void> loadOrders() async {
    try {
      final orders = await _repo.getPendingOrders();
      state = AsyncValue.data(orders);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> updateStatus(String orderId, String newStatus) async {
    try {
      await _repo.updateOrderStatus(orderId, newStatus);
      return true;
    } catch (e) {
      return false;
    }
  }

  void _listenToSocket() {
    _socketService.eventStream.listen((event) {
      if (!mounted) return;

      if (event.type == 'order_created' || 
          event.type == 'order_status_changed' || 
          event.type == 'token_verified') {
        loadOrders();
      }
    });
  }
}

// Inventory Provider
final adminInventoryProvider = StateNotifierProvider<AdminInventoryNotifier, AsyncValue<Map<String, dynamic>>>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  final socketService = ref.watch(socketServiceProvider);
  return AdminInventoryNotifier(repo, socketService);
});

class AdminInventoryNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final AdminRepository _repo;
  final SocketService _socketService;

  AdminInventoryNotifier(this._repo, this._socketService) : super(const AsyncValue.loading()) {
    loadInventory();
    _listenToSocket();
  }

  Future<void> loadInventory() async {
    try {
      final inv = await _repo.getInventory();
      state = AsyncValue.data(inv);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> restockItem(int itemId, double newQty) async {
    try {
      await _repo.updateInventory(itemId, {'quantity': newQty});
      loadInventory();
      return true;
    } catch (e) {
      return false;
    }
  }

  void _listenToSocket() {
    _socketService.eventStream.listen((event) {
      if (!mounted) return;
      if (event.type == 'inventory_alert') {
        loadInventory();
      }
    });
  }
}

// User List Provider
final adminUsersProvider = StateNotifierProvider<AdminUsersNotifier, AsyncValue<List<dynamic>>>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return AdminUsersNotifier(repo);
});

class AdminUsersNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  final AdminRepository _repo;

  AdminUsersNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadUsers();
  }

  Future<void> loadUsers({String? search}) async {
    try {
      final users = await _repo.getUsers(search: search);
      state = AsyncValue.data(users);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> toggleUser(int userId) async {
    try {
      await _repo.toggleUserActive(userId);
      loadUsers();
      return true;
    } catch (e) {
      return false;
    }
  }
}
