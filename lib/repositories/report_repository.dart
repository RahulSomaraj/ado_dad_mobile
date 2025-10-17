import 'package:ado_dad_user/common/api_service.dart';
import 'package:ado_dad_user/models/report_ad_model.dart';
import 'package:dio/dio.dart';

class ReportRepository {
  final Dio _dio = ApiService().dio;

  Future<ReportAdModel> reportAd(ReportAdModel reportData) async {
    try {
      print('📤 Reporting ad with data: ${reportData.toJson()}');

      final response = await _dio.post(
        '/user-reports',
        data: reportData.toJson(),
      );

      print('📥 Report response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Ad reported successfully');

        // Parse the response to get the created report with all details
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          return ReportAdModel.fromJson(responseData);
        } else {
          // If response doesn't contain the full report data, return the original data
          return reportData;
        }
      } else {
        print('⚠️ Failed to report ad, status: ${response.statusCode}');
        throw Exception('Failed to report ad');
      }
    } on DioException catch (e) {
      print('❌ Dio error in reportAd: $e');
      print('❌ Dio error type: ${e.type}');
      print('❌ Dio error message: ${e.message}');

      if (e.response != null) {
        print('❌ Response status code: ${e.response!.statusCode}');
        print('❌ Response data: ${e.response!.data}');
        print('❌ Response headers: ${e.response!.headers}');

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

        print('❌ Extracted error message: $errorMessage');
        throw Exception(errorMessage);
      } else {
        print('❌ No response data available');
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      print('❌ Unexpected error in reportAd: $e');
      print('❌ Error type: ${e.runtimeType}');
      throw Exception('Failed to report ad: $e');
    }
  }
}
