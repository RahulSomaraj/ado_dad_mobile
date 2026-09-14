import 'package:ado_dad_user/common/api_service.dart';
import 'package:ado_dad_user/models/app_version_model.dart';
import 'package:dio/dio.dart';

/// Fetches app version configuration from backend.
/// API response: { success, statusCode, message, data: { versions, forceUpdate, storeUrls } }.
class VersionRepository {
  final Dio _dio = ApiService().dio;

  /// Endpoint path for version config.
  static const String _versionPath = '/app-version';

  Future<AppVersionData?> getVersionConfig() async {
    try {
      final response = await _dio.get(_versionPath);

      if (response.statusCode != 200 || response.data is! Map<String, dynamic>) {
        return null;
      }
      final apiResponse = AppVersionResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
      final data = apiResponse.data;
      if (data != null) {
      } else {
      }
      return data;
    } on DioException catch (e) {
      if (e.response?.statusCode != null) {
        return null;
      }
      rethrow;
    }
  }

  /// Default store URLs if backend does not provide them.
  static String get defaultIosStoreUrl =>
      'https://apps.apple.com/app/ado-dad/idYOUR_APP_ID'; // Replace with real ID
  static String get defaultAndroidStoreUrl =>
      'https://play.google.com/store/apps/details?id=com.adodad.user';
}
