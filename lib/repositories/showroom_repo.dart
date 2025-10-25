import 'package:ado_dad_user/common/api_service.dart';
import 'package:ado_dad_user/models/showroom_user_model.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:dio/dio.dart';

class ShowroomRepo {
  final Dio _dio = ApiService().dio;

  Future<List<ShowroomUser>> fetchShowroomUsers() async {
    try {
      print('🔍 Fetching showroom users with type: SR');
      final response = await _dio.get('/users', queryParameters: {
        'type': 'SR',
      });

      print('📡 API Response Status: ${response.statusCode}');
      print('📡 API Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        print('📊 Response data type: ${responseData.runtimeType}');
        print('📊 Response data: $responseData');

        List<dynamic> data;

        // Handle different response structures
        if (responseData is List) {
          data = responseData;
          print('📊 Response is a List with ${data.length} items');
        } else if (responseData is Map<String, dynamic>) {
          // Check if data is wrapped in a 'data' field
          if (responseData.containsKey('data') &&
              responseData['data'] is List) {
            data = responseData['data'] as List<dynamic>;
            print(
                '📊 Response is a Map with data field containing ${data.length} items');
          } else if (responseData.containsKey('users') &&
              responseData['users'] is List) {
            data = responseData['users'] as List<dynamic>;
            print(
                '📊 Response is a Map with users field containing ${data.length} items');
          } else {
            print('❌ Unexpected response structure: $responseData');
            throw Exception(
                "Unexpected response structure: expected List or Map with 'data'/'users' field");
          }
        } else {
          print('❌ Unexpected response type: ${responseData.runtimeType}');
          throw Exception(
              "Unexpected response type: ${responseData.runtimeType}");
        }

        print('📊 Processing ${data.length} showroom users');

        final List<ShowroomUser> users = [];
        for (int i = 0; i < data.length; i++) {
          try {
            print('🔄 Parsing user $i: ${data[i]}');
            final user = ShowroomUser.fromJson(data[i]);
            users.add(user);
            print('✅ Successfully parsed user: ${user.name}');
          } catch (parseError) {
            print('❌ Error parsing user $i: $parseError');
            print('❌ User data: ${data[i]}');
          }
        }

        return users;
      } else {
        print('❌ API Error - Status: ${response.statusCode}');
        print('❌ API Response: ${response.data}');
        throw Exception(
            "Failed to load showroom users - Status: ${response.statusCode}");
      }
    } catch (e) {
      print('❌ Error fetching showroom users: $e');
      if (e is DioException) {
        print('❌ DioException details:');
        print('❌ - Type: ${e.type}');
        print('❌ - Message: ${e.message}');
        print('❌ - Response: ${e.response?.data}');
        print('❌ - Status Code: ${e.response?.statusCode}');
      }
      throw Exception("Error fetching showroom users: $e");
    }
  }

  Future<List<AddModel>> fetchShowroomUserAds({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('🔍 Fetching ads for showroom user: $userId');

      final response = await _dio.get(
        '/ads/user/$userId',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      print('📡 Showroom User Ads API Response Status: ${response.statusCode}');
      print('📡 Showroom User Ads API Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        final List<dynamic> rawData = responseData['data'] ?? responseData;

        print('📊 Processing ${rawData.length} ads for showroom user');

        final ads = rawData.map((json) => AddModel.fromJson(json)).toList();
        return ads;
      } else {
        print('❌ API Error - Status: ${response.statusCode}');
        print('❌ API Response: ${response.data}');
        throw Exception(
            "Failed to load showroom user ads - Status: ${response.statusCode}");
      }
    } catch (e) {
      print('❌ Error fetching showroom user ads: $e');
      if (e is DioException) {
        print('❌ DioException details:');
        print('❌ - Type: ${e.type}');
        print('❌ - Message: ${e.message}');
        print('❌ - Response: ${e.response?.data}');
        print('❌ - Status Code: ${e.response?.statusCode}');
      }
      throw Exception("Error fetching showroom user ads: $e");
    }
  }
}
