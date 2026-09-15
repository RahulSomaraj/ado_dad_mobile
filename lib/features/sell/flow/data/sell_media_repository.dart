import 'dart:io';

import 'package:ado_dad_user/common/api_service.dart';
import 'package:dio/dio.dart';

class UploadedMedia {
  final String mediaId;
  final String url;
  const UploadedMedia(this.mediaId, this.url);
}

/// Thrown when the file itself is refused (too big, wrong type) — retrying
/// the same bytes will not help.
class MediaRejected implements Exception {
  final String message;
  const MediaRejected(this.message);
  @override
  String toString() => message;
}

/// Upload intents are throttled per user; wait before retrying.
class MediaThrottled implements Exception {
  final Duration wait;
  const MediaThrottled(this.wait);
}

/// intent → signed PUT straight to S3 → complete.
class SellMediaRepository {
  SellMediaRepository({Dio? api, Dio? storage})
      : _api = api ?? ApiService().dio,
        _storage = storage ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 30),
            ));

  final Dio _api;
  final Dio _storage;

  Future<UploadedMedia> upload({
    required String path,
    required String contentType,
    required bool isVideo,
    required void Function(double progress) onProgress,
    CancelToken? cancelToken,
  }) async {
    final file = File(path);
    final size = await file.length();

    final Map<String, dynamic> intent;
    try {
      final res = await _api.post(
        '/v2/media/intents',
        data: {
          'kind': isVideo ? 'ad_video' : 'ad_image',
          'contentType': contentType,
          'size': size,
        },
        cancelToken: cancelToken,
      );
      intent = Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      _throwIfRejected(e, intent: true);
      rethrow;
    }

    final mediaId = '${intent['mediaId']}';
    final uploadUrl = '${intent['uploadUrl']}';
    final headers = <String, dynamic>{
      ...Map<String, dynamic>.from((intent['headers'] as Map?) ?? const {}),
      Headers.contentLengthHeader: size,
    };
    headers.putIfAbsent('Content-Type', () => contentType);

    // Send timeout scales with size: ~1 minute per 2 MB, at least 60 s.
    final sendSeconds = (60 + size / (2 * 1024 * 1024) * 60).round();
    await _storage.put(
      uploadUrl,
      data: file.openRead(),
      options: Options(
        headers: headers,
        sendTimeout: Duration(seconds: sendSeconds),
      ),
      cancelToken: cancelToken,
      onSendProgress: (sent, total) {
        final t = total > 0 ? total : size;
        if (t > 0) onProgress((sent / t).clamp(0.0, 0.98));
      },
    );

    // S3 can take a moment to report the object; 400 = "not uploaded yet".
    for (var attempt = 0;; attempt++) {
      try {
        final done = await _api.post('/v2/media/$mediaId/complete', cancelToken: cancelToken);
        final map = Map<String, dynamic>.from(done.data as Map);
        onProgress(1);
        return UploadedMedia(mediaId, '${map['url']}');
      } on DioException catch (e) {
        if (e.response?.statusCode == 400 && attempt < 3 && !CancelToken.isCancel(e)) {
          await Future<void>.delayed(Duration(milliseconds: 800 * (attempt + 1)));
          continue;
        }
        _throwIfRejected(e);
        rethrow;
      }
    }
  }

  void _throwIfRejected(DioException e, {bool intent = false}) {
    final status = e.response?.statusCode;
    if (status == 403) {
      throw const MediaRejected('Your account can’t upload right now');
    }
    if (intent && status == 400) {
      throw const MediaRejected('This file can’t be used');
    }
    if (status == 429) {
      final after = int.tryParse(e.response?.headers.value('retry-after') ?? '');
      throw MediaThrottled(Duration(seconds: after ?? 60));
    }
    if (status == 413) {
      throw const MediaRejected('This file is too large');
    }
    if (status == 415) {
      throw const MediaRejected('This file type isn’t supported');
    }
    if (status == 422) {
      final data = e.response?.data;
      final msg = data is Map ? '${data['message'] ?? ''}' : '';
      throw MediaRejected(msg.isEmpty ? 'This file can’t be used' : msg);
    }
  }
}
