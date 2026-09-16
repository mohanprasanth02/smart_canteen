import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/socket/socket_service.dart';
import '../../auth/data/auth_provider.dart';
import '../../cart/data/cart_provider.dart';
import 'order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(apiClientProvider));
});

// Active student orders provider
final activeOrdersProvider = StateNotifierProvider<ActiveOrdersNotifier, AsyncValue<List<dynamic>>>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  final socketService = ref.watch(socketServiceProvider);
  return ActiveOrdersNotifier(repo, socketService);
});

class ActiveOrdersNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  final OrderRepository _repo;
  final SocketService _socketService;

  ActiveOrdersNotifier(this._repo, this._socketService) : super(const AsyncValue.loading()) {
    loadActiveOrders();
    _listenToSocket();
  }

  Future<void> loadActiveOrders() async {
    try {
      final orders = await _repo.getActiveOrders();
      state = AsyncValue.data(orders);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _listenToSocket() {
    _socketService.eventStream.listen((event) {
      if (!mounted) return;

      if (event.type == 'order_status_changed' || event.type == 'order_created') {
        loadActiveOrders();
      } else if (event.type == 'token_verified') {
        loadActiveOrders(); // will remove from active list once marked completed/scanned
      }
    });
  }
}

// Student past orders history
final orderHistoryProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(orderRepositoryProvider).getOrders();
});

// Individual order detail tracking provider
final orderDetailProvider = StateNotifierProvider.family<OrderDetailNotifier, AsyncValue<Map<String, dynamic>>, String>((ref, orderId) {
  final repo = ref.watch(orderRepositoryProvider);
  final socketService = ref.watch(socketServiceProvider);
  return OrderDetailNotifier(repo, socketService, orderId);
});

class OrderDetailNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final OrderRepository _repo;
  final SocketService _socketService;
  final String _orderId;

  OrderDetailNotifier(this._repo, this._socketService, this._orderId) : super(const AsyncValue.loading()) {
    loadOrderDetail();
    _listenToSocket();
  }

  Future<void> loadOrderDetail() async {
    try {
      final detail = await _repo.getOrderDetail(_orderId);
      state = AsyncValue.data(detail);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _listenToSocket() {
    _socketService.eventStream.listen((event) {
      if (!mounted) return;

      if (event.type == 'order_status_changed' && event.data['order_id'] == _orderId) {
        loadOrderDetail();
      } else if (event.type == 'token_verified' && event.data['order_id'] == _orderId) {
        loadOrderDetail();
      } else if (event.type == 'payment_completed' && event.data['order_id'] == _orderId) {
        loadOrderDetail();
      }
    });
  }
}

// Checkout provider helper
final checkoutStateProvider = StateNotifierProvider<CheckoutNotifier, AsyncValue<Map<String, dynamic>?>>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  final cartNotifier = ref.watch(cartStateProvider.notifier);
  return CheckoutNotifier(repo, cartNotifier);
});

class CheckoutNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final OrderRepository _repo;
  final CartStateNotifier _cartNotifier;

  CheckoutNotifier(this._repo, this._cartNotifier) : super(const AsyncValue.data(null));

  Future<bool> placeOrder({
    required String pickupTime,
    required String notes,
    required String paymentMethod,
  }) async {
    state = const AsyncValue.loading();
    try {
      final order = await _repo.placeOrder(
        pickupTime: pickupTime,
        notes: notes,
        paymentMethod: paymentMethod,
      );
      state = AsyncValue.data(order['order']);
      
      // refresh cart on success
      _cartNotifier.loadCart();
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}
