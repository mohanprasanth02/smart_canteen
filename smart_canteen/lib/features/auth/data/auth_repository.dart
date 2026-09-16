import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      
      final data = response.data;
      if (data['access_token'] != null) {
        await _apiClient.saveTokens(
          access: data['access_token'],
          refresh: data['refresh_token'],
        );
      }
      return data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> adminLogin(String username, String password) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.adminLogin,
        data: {'username': username, 'password': password},
      );
      
      final data = response.data;
      if (data['access_token'] != null) {
        await _apiClient.saveTokens(
          access: data['access_token'],
          refresh: data['refresh_token'],
        );
      }
      return data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String registerNumber,
    required String department,
    required int year,
    required String mobileNumber,
    required String email,
    required String password,
    String? profilePhoto,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.register,
        data: {
          'full_name': fullName,
          'register_number': registerNumber,
          'department': department,
          'year': year,
          'mobile_number': mobileNumber,
          'email': email,
          'password': password,
          'profile_photo': profilePhoto,
        },
      );
      final data = response.data;
      if (data['access_token'] != null) {
        await _apiClient.saveTokens(
          access: data['access_token'],
          refresh: data['refresh_token'],
        );
      }
      return data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.me);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    await _apiClient.clearTokens();
  }

  Future<bool> checkAuth() async {
    final token = await _apiClient.getAccessToken();
    return token != null;
  }

  Future<void> saveFcmToken(String token) async {
    try {
      await _apiClient.dio.post(
        '/api/auth/fcm-token',
        data: {'fcm_token': token},
      );
    } on DioException catch (e) {
      print('[FCM] Token upload error: $e');
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
