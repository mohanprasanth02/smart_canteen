import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class MenuRepository {
  final ApiClient _apiClient;

  MenuRepository(this._apiClient);

  Future<List<dynamic>> getCategories() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.categories);
      return response.data['categories'] ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getFoodItems({
    int? categoryId,
    bool? isVeg,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (categoryId != null) queryParams['category_id'] = categoryId;
      if (isVeg != null) queryParams['is_veg'] = isVeg;
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;

      final response = await _apiClient.dio.get(
        ApiConstants.foodItems,
        queryParameters: queryParams,
      );
      return response.data['items'] ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getSpecials() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.specials);
      return response.data['specials'] ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getPopular() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.popular);
      return response.data['popular'] ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> searchFood(String query) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.search,
        queryParameters: {'q': query},
      );
      return response.data['items'] ?? [];
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
    return 'Failed to load menu. Check network.';
  }
}
