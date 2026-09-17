import 'package:ado_dad_user/common/api_service.dart';
import 'package:ado_dad_user/models/app_version_model.dart';
import 'package:dio/dio.dart';

/// Fetches app version configuration from backend.
/// API response: { success, statusCode, message,
///   data: { versions, forceUpdate, storeUrls, builds, releaseNotes } }.
class VersionRepository {
  final Dio _dio = ApiService().dio;

  /// Endpoint path for version config.
  static const String _versionPath = '/app-version';

  /// Returns null when the config is missing or the server answered with an
  /// error status. Rethrows transport errors (offline, timeout) so the caller
  /// can retry later instead of treating it as "no update".
  Future<AppVersionData?> getVersionConfig() async {
    try {
      final response = await _dio.get(_versionPath);

      if (response.statusCode != 200 ||
          response.data is! Map<String, dynamic>) {
        return null;
      }
      return AppVersionResponse.fromJson(
        response.data as Map<String, dynamic>,
      ).data;
    } on DioException catch (e) {
      if (e.response?.statusCode != null) {
        return null;
      }
      rethrow;
    }
  }

  /// Play Store listing for [packageName]. Used only when the backend does not
  /// send an Android store URL. There is no iOS equivalent without the numeric
  /// App Store id, so iOS relies on `storeUrls.ios` from the backend.
  static String androidStoreUrlFor(String packageName) =>
      'https://play.google.com/store/apps/details?id=$packageName';
}
