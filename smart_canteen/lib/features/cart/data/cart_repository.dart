import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class CartRepository {
  final ApiClient _apiClient;

  CartRepository(this._apiClient);

  Future<Map<String, dynamic>> getCart() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.cart);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> addToCart(int foodItemId, int quantity) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.cartItems,
        data: {'food_item_id': foodItemId, 'quantity': quantity},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateCartItem(int cartItemId, int quantity) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.cartItems}/$cartItemId',
        data: {'quantity': quantity},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> removeFromCart(int cartItemId) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiConstants.cartItems}/$cartItemId',
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> clearCart() async {
    try {
      await _apiClient.dio.delete(ApiConstants.cart);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('error')) {
        return data['error'].toString();
      }
    }
    return 'Cart operation failed. Check connection.';
  }
}
