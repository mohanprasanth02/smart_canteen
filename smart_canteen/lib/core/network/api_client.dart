import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class ApiClient {
  late final Dio dio;
  final _storage = const FlutterSecureStorage();

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Dynamically load persisted server IP
          final savedIp = await _storage.read(key: 'server_ip');
          if (savedIp != null && savedIp.isNotEmpty) {
            options.baseUrl = 'http://$savedIp:5000';
          } else {
            options.baseUrl = ApiConstants.baseUrl;
          }

          // Attach Access Token if it exists
          final token = await getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // If token expired (401 Unauthorized), attempt to refresh
          if (e.response?.statusCode == 401 &&
              e.requestOptions.path != ApiConstants.login &&
              e.requestOptions.path != ApiConstants.adminLogin) {
            try {
              final refreshed = await refreshTokens();
              if (refreshed) {
                // Retry request with new token
                final newAccessToken = await getAccessToken();
                final opts = Options(
                  method: e.requestOptions.method,
                  headers: {
                    ...e.requestOptions.headers,
                    'Authorization': 'Bearer $newAccessToken',
                  },
                );
                final cloneReq = await dio.request(
                  e.requestOptions.path,
                  options: opts,
                  data: e.requestOptions.data,
                  queryParameters: e.requestOptions.queryParameters,
                );
                return handler.resolve(cloneReq);
              }
            } catch (err) {
              // Log out / clear tokens if refresh fails
              await clearTokens();
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  Future<void> saveTokens({required String access, required String refresh}) async {
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<bool> refreshTokens() async {
    final refresh = await getRefreshToken();
    if (refresh == null) return false;

    try {
      final response = await dio.post(
        '/api/auth/refresh',
        options: Options(
          headers: {'Authorization': 'Bearer $refresh'},
        ),
      );
      if (response.statusCode == 200) {
        final newAccess = response.data['access_token'];
        await _storage.write(key: 'access_token', value: newAccess);
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }
}
