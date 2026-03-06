import 'package:ado_dad_user/common/api_service.dart';
import 'package:ado_dad_user/models/notification_model.dart';
import 'package:dio/dio.dart';

class NotificationRepository {
  final Dio _dio = ApiService().dio;

  /// Fetches a page of notifications.
  /// [page] and [limit] are sent as query params: /notifications?page=1&limit=10
  Future<NotificationListResponse> getNotifications({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/notifications',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final map = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        return NotificationListResponse.fromJson(map);
      } else {
        throw Exception(
            'Failed to fetch notifications: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception(DioErrorHandler.handleError(e));
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }
}
