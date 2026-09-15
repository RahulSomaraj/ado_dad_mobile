import 'package:ado_dad_user/common/api_service.dart';
import 'package:ado_dad_user/models/report_ad_model.dart';
import 'package:dio/dio.dart';

class ReportRepository {
  final Dio _dio = ApiService().dio;

  Future<ReportAdModel> reportAd(ReportAdModel reportData) async {
    try {
      final response = await _dio.post(
        '/user-reports',
        data: reportData.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse the response to get the created report with all details
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          return ReportAdModel.fromJson(responseData);
        } else {
          // If response doesn't contain the full report data, return the original data
          return reportData;
        }
      } else {
        throw Exception('Failed to report ad');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        // Try to extract error message from different possible fields
        String errorMessage = 'Failed to report ad';
        if (e.response!.data is Map<String, dynamic>) {
          final responseData = e.response!.data as Map<String, dynamic>;
          errorMessage = responseData['message'] ??
              responseData['error'] ??
              responseData['detail'] ??
              'Failed to report ad';
        } else if (e.response!.data is String) {
          errorMessage = e.response!.data as String;
        }

        throw Exception(errorMessage);
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to report ad: $e');
    }
  }
}
