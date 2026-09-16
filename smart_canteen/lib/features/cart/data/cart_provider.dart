import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_provider.dart';
import 'cart_repository.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(ref.watch(apiClientProvider));
});

final cartStateProvider = StateNotifierProvider<CartStateNotifier, AsyncValue<Map<String, dynamic>>>((ref) {
  final repo = ref.watch(cartRepositoryProvider);
  return CartStateNotifier(repo);
});

class CartStateNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final CartRepository _repo;

  CartStateNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadCart();
  }

  Future<void> loadCart() async {
    try {
      final cart = await _repo.getCart();
      state = AsyncValue.data(cart);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> addToCart(int foodItemId, int quantity) async {
    try {
      final response = await _repo.addToCart(foodItemId, quantity);
      state = AsyncValue.data(response['cart']);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateQuantity(int cartItemId, int newQuantity) async {
    try {
      final response = await _repo.updateCartItem(cartItemId, newQuantity);
      state = AsyncValue.data(response['cart']);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeFromCart(int cartItemId) async {
    try {
      final response = await _repo.removeFromCart(cartItemId);
      state = AsyncValue.data(response['cart']);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> clearCart() async {
    try {
      await _repo.clearCart();
      state = const AsyncValue.data({
        'id': null,
        'user_id': null,
        'items': [],
        'item_count': 0,
        'subtotal': 0,
        'tax': 0,
        'total': 0,
      });
    } catch (e) {
      // Keep state as is
    }
  }
}
