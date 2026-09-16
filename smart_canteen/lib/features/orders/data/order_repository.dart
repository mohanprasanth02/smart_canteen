import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class OrderRepository {
  final ApiClient _apiClient;

  OrderRepository(this._apiClient);

  Future<Map<String, dynamic>> placeOrder({
    required String pickupTime,
    required String notes,
    required String paymentMethod,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.orders,
        data: {
          'pickup_time': pickupTime,
          'notes': notes,
          'payment_method': paymentMethod,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getOrders({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;

      final response = await _apiClient.dio.get(
        ApiConstants.orders,
        queryParameters: queryParams,
      );
      return response.data['orders'] ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getActiveOrders() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.activeOrders);
      return response.data['orders'] ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getOrderDetail(String orderId) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.orders}/$orderId');
      return response.data['order'] ?? {};
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> processPayment(String orderId, String method) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.paymentPay}/$orderId/pay',
        data: {'payment_method': method},
      );
      return response.data;
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
    return 'Order request failed. Check network.';
  }
}
