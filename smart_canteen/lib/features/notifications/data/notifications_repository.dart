import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class NotificationsRepository {
  final ApiClient _apiClient;

  NotificationsRepository(this._apiClient);

  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.notifications);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markAsRead(int notifId) async {
    try {
      await _apiClient.dio.put('${ApiConstants.notifications}/$notifId/read');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiClient.dio.put(ApiConstants.markAllNotificationsRead);
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
    return 'Connection failed. Please check network.';
  }
}
