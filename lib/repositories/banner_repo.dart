import 'package:ado_dad_user/common/api_service.dart';
import 'package:ado_dad_user/models/banner_model.dart';
import 'package:dio/dio.dart';

class BannerRepository {
  final Dio _dio = ApiService().dio;

  Future<List<BannerModel>> fetchBanners() async {
    try {
      final response = await _dio.get('/banners');

      if (response.statusCode == 200) {
        final List<dynamic> bannersJson = response.data['banners'];
        return bannersJson
            .map((banner) => BannerModel.fromJson(banner))
            .toList();
      } else {
        throw Exception("Failed to fetch banners: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      throw Exception(DioErrorHandler.handleError(e));
    } catch (e) {
      throw Exception("Unexpected error: ${e.toString()}");
    }
  }
}
