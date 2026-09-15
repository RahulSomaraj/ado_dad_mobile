// REST client for chat (Phase 5 · M2).
//
// Uses the shared ApiService Dio instance so auth headers and the single
// token-refresh path apply (replaces services/chat_api_service.dart, F-40).

import 'dart:async';
import 'dart:io' show SocketException;
import 'dart:typed_data';

import 'package:ado_dad_user/common/api_service.dart';
import 'package:dio/dio.dart';

import 'chat_models.dart';

class ChatApi {
  ChatApi({Dio? dio, Dio? uploadDio})
      : _dio = dio ?? ApiService().dio,
        _uploadDio = uploadDio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(minutes: 2),
              receiveTimeout: const Duration(seconds: 30),
            ));

  final Dio _dio;

  /// Plain Dio for S3 PUTs: must NOT carry our Authorization header.
  final Dio _uploadDio;

  Future<ChatRoomPage> listRooms({
    int limit = 20,
    String? cursor,
    String filter = 'all',
    String? query,
  }) {
    return _guard(() async {
      final res = await _dio.get('/chats/rooms', queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
        if (filter != 'all') 'filter': filter,
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      });
      final body = _map(res.data);
      final rooms = (body['data'] as List? ?? const [])
          .whereType<Map>()
          .map((r) => ChatRoom.fromJson(Map<String, dynamic>.from(r)))
          .where((r) => r.roomId.isNotEmpty)
          .toList();
      return ChatRoomPage(rooms, body['nextCursor']?.toString());
    });
  }

  Future<ChatRoom> getRoom(String roomId) => _guard(() async {
        final res =
            await _dio.get('/chats/rooms/${Uri.encodeComponent(roomId)}');
        return ChatRoom.fromJson(_data(res.data));
      });

  /// Idempotent get-or-create for an ad.
  Future<ChatRoom> createRoom(String adId) => _guard(() async {
        final res = await _dio.post('/chats/rooms', data: {'adId': adId});
        return ChatRoom.fromJson(_data(res.data));
      });

  Future<ChatMessagePage> getMessages(
    String roomId, {
    int limit = 30,
    String? cursor,
  }) =>
      _guard(() async {
        final res = await _dio.get(
          '/chats/rooms/${Uri.encodeComponent(roomId)}/messages',
          queryParameters: {
            'limit': limit,
            if (cursor != null) 'cursor': cursor
          },
        );
        return _page(res.data, ascending: false);
      });

  /// Messages newer than [afterId], returned newest-first like every other page.
  Future<ChatMessagePage> getMessagesAfter(String roomId, String afterId,
          {int limit = 100}) =>
      _guard(() async {
        final res = await _dio.get(
          '/chats/rooms/${Uri.encodeComponent(roomId)}/messages',
          queryParameters: {'limit': limit, 'after': afterId},
        );
        return _page(res.data, ascending: true);
      });

  Future<ChatMessage> sendMessage(
    String roomId, {
    required String clientMessageId,
    required MessageType type,
    String? content,
    List<ChatAttachment> attachments = const [],
  }) =>
      _guard(() async {
        final res = await _dio.post(
          '/chats/rooms/${Uri.encodeComponent(roomId)}/messages',
          data: {
            'clientMessageId': clientMessageId,
            'type': type.wire,
            if (content != null && content.isNotEmpty) 'content': content,
            if (attachments.isNotEmpty)
              'attachments': attachments.map((a) => a.toJson()).toList(),
          },
        );
        return ChatMessage.fromJson(_data(res.data));
      });

  Future<void> markRead(String roomId, {String? lastMessageId}) =>
      _guard(() async {
        await _dio.post(
          '/chats/rooms/${Uri.encodeComponent(roomId)}/read',
          data: {if (lastMessageId != null) 'lastMessageId': lastMessageId},
        );
      });

  Future<int> unreadTotal() async => (await unreadSummary()).total;

  /// Unread messages and unread chats, counted on the server.
  Future<({int total, int rooms})> unreadSummary() => _guard(() async {
        final res = await _dio.get('/chats/unread-count');
        final data = _data(res.data);
        return (
          total: (data['total'] as num?)?.toInt() ?? 0,
          rooms: (data['rooms'] as num?)?.toInt() ?? 0,
        );
      });

  /// Per-user archive (screen 01 long-press).
  Future<void> setArchived(String roomId, bool archived) => _guard(() async {
        final path = '/chats/rooms/${Uri.encodeComponent(roomId)}/archive';
        if (archived) {
          await _dio.post(path);
        } else {
          await _dio.delete(path);
        }
      });

  Future<void> markUnread(String roomId) => _guard(() async {
        await _dio.post('/chats/rooms/${Uri.encodeComponent(roomId)}/unread');
      });

  Future<ChatUploadTicket> createUpload(
    String roomId, {
    required String kind,
    required String mimeType,
    required int size,
  }) =>
      _guard(() async {
        final res = await _dio.post(
          '/chats/rooms/${Uri.encodeComponent(roomId)}/uploads',
          data: {'kind': kind, 'mimeType': mimeType, 'size': size},
        );
        return ChatUploadTicket.fromJson(_data(res.data));
      });

  /// PUT the bytes to S3 using exactly the headers the ticket was signed with.
  Future<void> upload(
    ChatUploadTicket ticket,
    Uint8List bytes, {
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) =>
      _guard(() async {
        await _uploadDio.put(
          ticket.uploadUrl,
          data: Stream.fromIterable(_chunks(bytes)),
          cancelToken: cancelToken,
          options: Options(headers: {
            ...ticket.headers,
            Headers.contentLengthHeader: bytes.length,
          }),
          onSendProgress: (sent, total) {
            if (onProgress != null && total > 0) onProgress(sent / total);
          },
        );
      });

  // ---------------------------------------------------------------------------

  Iterable<List<int>> _chunks(Uint8List bytes, [int size = 64 * 1024]) sync* {
    for (var i = 0; i < bytes.length; i += size) {
      yield bytes.sublist(i, i + size > bytes.length ? bytes.length : i + size);
    }
  }

  ChatMessagePage _page(dynamic raw, {required bool ascending}) {
    final data = _data(raw);
    var messages = (data['messages'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    if (ascending) messages = messages.reversed.toList();
    return ChatMessagePage(
      messages,
      data['nextCursor']?.toString(),
      data['hasMore'] == true,
    );
  }

  Map<String, dynamic> _map(dynamic raw) =>
      raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

  Map<String, dynamic> _data(dynamic raw) {
    final body = _map(raw);
    final data = body['data'];
    return data is Map ? Map<String, dynamic>.from(data) : body;
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw mapDioError(e);
    } on SocketException {
      throw const ChatFailure(ChatFailureKind.offline);
    } on TimeoutException {
      throw const ChatFailure(ChatFailureKind.timeout);
    } on ChatFailure {
      rethrow;
    } catch (_) {
      // Unexpected response shape etc. — never let a non-ChatFailure escape to cubits.
      throw const ChatFailure(ChatFailureKind.unknown);
    }
  }

  static ChatFailure mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ChatFailure(ChatFailureKind.timeout);
      case DioExceptionType.connectionError:
        return const ChatFailure(ChatFailureKind.offline);
      case DioExceptionType.cancel:
        return const ChatFailure(ChatFailureKind.unknown, code: 'CANCELLED');
      default:
        break;
    }
    final status = e.response?.statusCode;
    if (status == null) {
      return e.error is SocketException
          ? const ChatFailure(ChatFailureKind.offline)
          : const ChatFailure(ChatFailureKind.unknown);
    }
    final body = e.response?.data;
    String? code;
    String? message;
    if (body is Map) {
      code = body['code']?.toString();
      final m = body['message'];
      message = m is List ? m.join(', ') : m?.toString();
    }
    return ChatFailure.fromCode(code, message: message, status: status);
  }
}
