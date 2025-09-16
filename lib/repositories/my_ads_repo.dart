import 'package:ado_dad_user/common/api_service.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:dio/dio.dart';
import 'package:ado_dad_user/models/my_ads_model.dart';

class MyAdsRepo {
  final Dio _dio = ApiService().dio;

  Future<PaginatedMyAdsResponse> fetchMyAds({
    int page = 1,
    int limit = 100,
    String sortBy = 'createdAt',
    String sortOrder = 'ASC',
  }) async {
    try {
      // Debug: Check if user is authenticated
      final token = await getToken();
      if (token == null) {
        throw Exception('User not authenticated. Please login again.');
      }

      print('🔐 Fetching My Ads with token: ${token.substring(0, 20)}...');

      final requestBody = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

      print('📤 My Ads Request: POST /ads/my-ads with body: $requestBody');

      final response = await _dio.post(
        '/ads/my-ads',
        data: requestBody,
        options: Options(responseType: ResponseType.json),
      );

      print('📥 My Ads Response Status: ${response.statusCode}');
      print('📥 My Ads Response Data: ${response.data}');

      dynamic raw = response.data;

      List list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic> && raw['data'] is List) {
        list = raw['data'] as List;
      } else {
        throw StateError('Unexpected response: ${raw.runtimeType} -> $raw');
      }

      final int total = raw is Map<String, dynamic>
          ? (raw['total'] is int ? raw['total'] as int : list.length)
          : list.length;
      final bool hasNext = (page * limit) < total;

      final ads = list
          .whereType<Map<String, dynamic>>()
          .map((obj) => MyAd.fromJson(obj))
          .toList();

      return PaginatedMyAdsResponse(data: ads, hasNext: hasNext);
    } on DioException catch (e) {
      throw Exception(DioErrorHandler.handleError(e));
    } catch (e) {
      throw Exception('Failed to fetch my ads: $e');
    }
  }
}

class PaginatedMyAdsResponse {
  final List<MyAd> data;
  final bool hasNext;

  PaginatedMyAdsResponse({required this.data, required this.hasNext});
}
