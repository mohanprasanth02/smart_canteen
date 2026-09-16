import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class AdminRepository {
  final ApiClient _apiClient;

  AdminRepository(this._apiClient);

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.adminDashboard);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getMenu() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.adminMenu);
      return response.data['items'] ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> addMenuItem(Map<String, dynamic> itemData) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.adminMenu,
        data: itemData,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateMenuItem(int itemId, Map<String, dynamic> itemData) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.adminMenu}/$itemId',
        data: itemData,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteMenuItem(int itemId) async {
    try {
      await _apiClient.dio.delete('${ApiConstants.adminMenu}/$itemId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateStock(int itemId, int quantity) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.adminMenu}/$itemId/stock',
        data: {'quantity': quantity},
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
        ApiConstants.adminOrders,
        queryParameters: queryParams,
      );
      return response.data['orders'] ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getPendingOrders() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.adminPendingOrders);
      return response.data['orders'] ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.orders}/$orderId/status',
        data: {'status': status},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> verifyQr(String qrData) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.verifyQr,
        data: {'qr_data': qrData},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getUsers({String? search}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null) queryParams['search'] = search;

      final response = await _apiClient.dio.get(
        ApiConstants.adminUsers,
        queryParameters: queryParams,
      );
      return response.data['users'] ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> toggleUserActive(int userId) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.adminUsers}/$userId/toggle',
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getInventory() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.adminInventory);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> addInventory(Map<String, dynamic> itemData) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.adminInventory,
        data: itemData,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateInventory(int itemId, Map<String, dynamic> itemData) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.adminInventory}/$itemId',
        data: itemData,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getDailyAnalytics({int days = 7}) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/analytics/daily',
        queryParameters: {'days': days},
      );
      return response.data['daily_sales'] ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getTopFoods() async {
    try {
      final response = await _apiClient.dio.get('/api/analytics/top-foods');
      return response.data['top_foods'] ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getPeakHours() async {
    try {
      final response = await _apiClient.dio.get('/api/analytics/peak-hours');
      return response.data['peak_hours'] ?? [];
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
    return 'Admin action failed. Check network connection.';
  }
}
