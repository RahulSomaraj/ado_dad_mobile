// Chat domain models (Phase 5 · M1).
//
// Pure Dart, no Flutter imports, so they are unit-testable with `dart test`.
// Every timestamp is converted to LOCAL time at parse (audit F-11).

import 'dart:typed_data';

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v.toLocal();
  final parsed = DateTime.tryParse(v.toString());
  return parsed?.toLocal();
}

int _asInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

String? _asStringOrNull(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

/// Server placeholder used when a user never set an avatar.
const _defaultAvatar = 'default-profile-pic-url';

String? _avatar(dynamic v) {
  final s = _asStringOrNull(v);
  if (s == null || s == _defaultAvatar || !s.startsWith('http')) return null;
  return s;
}

// ---------------------------------------------------------------------------
// Rooms
// ---------------------------------------------------------------------------

enum ChatRole { buying, selling }

enum AdAvailability { live, sold, unavailable }

class ChatOtherUser {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? phoneNumber;
  final String? countryCode;

  const ChatOtherUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.phoneNumber,
    this.countryCode,
  });

  /// `+919847012345` style, or null when the user hid / has no number.
  String? get dialNumber {
    final p = phoneNumber?.trim();
    if (p == null || p.isEmpty) return null;
    if (p.startsWith('+')) return p;
    final cc = countryCode?.trim() ?? '';
    return '$cc$p';
  }

  String get initial {
    final n = name.trim();
    return n.isEmpty ? '?' : n.characters1.toUpperCase();
  }

  factory ChatOtherUser.fromJson(Map<String, dynamic> j) => ChatOtherUser(
        id: (j['id'] ?? j['_id'] ?? '').toString(),
        name: (j['name'] ?? '').toString().trim().isEmpty
            ? 'AdoDad user'
            : j['name'].toString().trim(),
        avatarUrl: _avatar(j['profilePic']),
        phoneNumber: _asStringOrNull(j['phoneNumber']),
        countryCode: _asStringOrNull(j['countryCode']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'profilePic': avatarUrl,
        'phoneNumber': phoneNumber,
        'countryCode': countryCode,
      };
}

extension on String {
  /// First user-perceived character (good enough for initials; avoids a
  /// dependency on package:characters).
  String get characters1 =>
      runes.isEmpty ? '' : String.fromCharCode(runes.first);
}

class ChatAd {
  final String id;
  final String title;
  final num? price;
  final String? imageUrl;
  final AdAvailability availability;

  const ChatAd({
    required this.id,
    required this.title,
    this.price,
    this.imageUrl,
    this.availability = AdAvailability.live,
  });

  factory ChatAd.fromJson(Map<String, dynamic> j) => ChatAd(
        id: (j['id'] ?? j['_id'] ?? '').toString(),
        title: (j['title'] ?? 'Listing').toString(),
        price: j['price'] is num
            ? j['price'] as num
            : num.tryParse('${j['price']}'),
        imageUrl: _asStringOrNull(j['image']) ??
            ((j['images'] is List && (j['images'] as List).isNotEmpty)
                ? (j['images'] as List).first?.toString()
                : null),
        availability: switch (j['status']) {
          'sold' => AdAvailability.sold,
          'unavailable' => AdAvailability.unavailable,
          _ => AdAvailability.live,
        },
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'price': price,
        'image': imageUrl,
        'status': availability.name,
      };
}

class ChatLastMessage {
  final String id;
  final MessageType type;
  final String preview;
  final String senderId;
  final DateTime createdAt;

  /// My own last message only: [MessageStatus.sent] or [MessageStatus.read]. Null otherwise.
  final MessageStatus? status;

  const ChatLastMessage({
    required this.id,
    required this.type,
    required this.preview,
    required this.senderId,
    required this.createdAt,
    this.status,
  });

  factory ChatLastMessage.fromJson(Map<String, dynamic> j) => ChatLastMessage(
        id: (j['id'] ?? '').toString(),
        type: MessageTypeX.parse(j['type']),
        preview: (j['preview'] ?? j['content'] ?? '').toString(),
        senderId: (j['senderId'] ?? '').toString(),
        createdAt: _parseDate(j['createdAt']) ?? DateTime.now(),
        status: switch (j['status']) {
          'read' => MessageStatus.read,
          'sent' => MessageStatus.sent,
          _ => null,
        },
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.wire,
        'preview': preview,
        'senderId': senderId,
        'createdAt': createdAt.toUtc().toIso8601String(),
        if (status != null) 'status': status!.name,
      };
}

class ChatRoom {
  final String roomId;
  final String adId;
  final ChatRole myRole;
  final bool isClosed;
  final bool isArchived;
  final int unreadCount;
  final DateTime? lastActivityAt;
  final DateTime? createdAt;
  final ChatOtherUser? otherUser;
  final ChatAd? ad;
  final ChatLastMessage? lastMessage;

  const ChatRoom({
    required this.roomId,
    required this.adId,
    required this.myRole,
    this.isClosed = false,
    this.isArchived = false,
    this.unreadCount = 0,
    this.lastActivityAt,
    this.createdAt,
    this.otherUser,
    this.ad,
    this.lastMessage,
  });

  /// Display name in lists and headers.
  String get title => otherUser?.name ?? 'AdoDad user';

  /// Time shown in the list: last message, else when the chat was opened.
  DateTime? get sortTime =>
      lastMessage?.createdAt ?? lastActivityAt ?? createdAt;

  bool get hasUnread => unreadCount > 0;

  ChatRoom copyWith({
    int? unreadCount,
    ChatLastMessage? lastMessage,
    DateTime? lastActivityAt,
    bool? isClosed,
    bool? isArchived,
  }) =>
      ChatRoom(
        roomId: roomId,
        adId: adId,
        myRole: myRole,
        isClosed: isClosed ?? this.isClosed,
        isArchived: isArchived ?? this.isArchived,
        unreadCount: unreadCount ?? this.unreadCount,
        lastActivityAt: lastActivityAt ?? this.lastActivityAt,
        createdAt: createdAt,
        otherUser: otherUser,
        ad: ad,
        lastMessage: lastMessage ?? this.lastMessage,
      );

  /// Accepts the v2 RoomDto and (best effort) the legacy room shape.
  factory ChatRoom.fromJson(Map<String, dynamic> j) {
    final other = j['otherUser'];
    final ad = j['ad'] ?? j['adDetails'];
    final last = j['lastMessage'];
    final legacyLast = j['latestMessage'];
    return ChatRoom(
      roomId: (j['roomId'] ?? j['id'] ?? '').toString(),
      adId: (j['adId'] ?? '').toString(),
      myRole: j['myRole'] == 'selling' ? ChatRole.selling : ChatRole.buying,
      isClosed: j['isClosed'] == true,
      isArchived: j['archived'] == true,
      unreadCount: _asInt(j['unreadCount']),
      lastActivityAt: _parseDate(j['lastMessageAt']),
      createdAt: _parseDate(j['createdAt']),
      otherUser: other is Map
          ? ChatOtherUser.fromJson(Map<String, dynamic>.from(other))
          : null,
      ad: ad is Map ? ChatAd.fromJson(Map<String, dynamic>.from(ad)) : null,
      lastMessage: last is Map
          ? ChatLastMessage.fromJson(Map<String, dynamic>.from(last))
          : legacyLast is Map
              ? ChatLastMessage.fromJson({
                  ...Map<String, dynamic>.from(legacyLast),
                  'preview': legacyLast['content'],
                })
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'adId': adId,
        'myRole': myRole.name,
        'isClosed': isClosed,
        'archived': isArchived,
        'unreadCount': unreadCount,
        'lastMessageAt': lastActivityAt?.toUtc().toIso8601String(),
        'createdAt': createdAt?.toUtc().toIso8601String(),
        'otherUser': otherUser?.toJson(),
        'ad': ad?.toJson(),
        'lastMessage': lastMessage?.toJson(),
      };
}

class ChatRoomPage {
  final List<ChatRoom> rooms;
  final String? nextCursor;
  const ChatRoomPage(this.rooms, this.nextCursor);
}

// ---------------------------------------------------------------------------
// Messages
// ---------------------------------------------------------------------------

enum MessageType { text, image, audio, file, system }

extension MessageTypeX on MessageType {
  String get wire => name;

  static MessageType parse(dynamic v) => switch (v?.toString()) {
        'image' => MessageType.image,
        'audio' => MessageType.audio,
        'file' => MessageType.file,
        'system' => MessageType.system,
        _ => MessageType.text,
      };
}

/// Delivery state of a message *I* sent. Incoming messages are always [sent].
enum MessageStatus { sending, sent, read, failed }

class ChatAttachment {
  final String type; // image | audio | file
  final String url;
  final String? mimeType;
  final int? size;
  final int? durationSec;
  final int? width;
  final int? height;

  const ChatAttachment({
    required this.type,
    required this.url,
    this.mimeType,
    this.size,
    this.durationSec,
    this.width,
    this.height,
  });

  factory ChatAttachment.fromJson(Map<String, dynamic> j) => ChatAttachment(
        type: (j['type'] ?? 'file').toString(),
        url: (j['url'] ?? '').toString(),
        mimeType: _asStringOrNull(j['mimeType']),
        size: j['size'] == null ? null : _asInt(j['size']),
        durationSec: j['duration'] == null ? null : _asInt(j['duration']),
        width: j['width'] == null ? null : _asInt(j['width']),
        height: j['height'] == null ? null : _asInt(j['height']),
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'url': url,
        if (mimeType != null) 'mimeType': mimeType,
        if (size != null) 'size': size,
        if (durationSec != null) 'duration': durationSec,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
      };
}

enum ChatFailureKind {
  offline,
  timeout,
  server,
  session,
  suspended,
  notParticipant,
  notFound,
  closed,
  blocked,
  invalid,
  rateLimited,
  unknown,
}

class ChatFailure implements Exception {
  final ChatFailureKind kind;
  final String? code;
  final String? serverMessage;

  const ChatFailure(this.kind, {this.code, this.serverMessage});

  /// Network-type failures are retried automatically; the rest need the user.
  bool get isRetryable =>
      kind == ChatFailureKind.offline ||
      kind == ChatFailureKind.timeout ||
      kind == ChatFailureKind.server ||
      kind == ChatFailureKind.rateLimited;

  static ChatFailure fromCode(String? code, {String? message, int? status}) {
    final kind = switch (code) {
      'TOKEN_EXPIRED' || 'UNAUTHORIZED' => ChatFailureKind.session,
      'SUSPENDED' => ChatFailureKind.suspended,
      'NOT_PARTICIPANT' => ChatFailureKind.notParticipant,
      'ROOM_NOT_FOUND' || 'AD_NOT_FOUND' => ChatFailureKind.notFound,
      'ROOM_CLOSED' || 'AD_UNAVAILABLE' => ChatFailureKind.closed,
      'CONTENT_BLOCKED' => ChatFailureKind.blocked,
      'VALIDATION' || 'ATTACHMENT_INVALID' => ChatFailureKind.invalid,
      'RATE_LIMITED' => ChatFailureKind.rateLimited,
      _ => switch (status) {
          401 => ChatFailureKind.session,
          403 => ChatFailureKind.notParticipant,
          404 => ChatFailureKind.notFound,
          409 => ChatFailureKind.closed,
          422 => ChatFailureKind.blocked,
          429 => ChatFailureKind.rateLimited,
          int s when s >= 500 => ChatFailureKind.server,
          int s when s >= 400 => ChatFailureKind.invalid,
          _ => ChatFailureKind.unknown,
        },
    };
    return ChatFailure(kind, code: code, serverMessage: message);
  }

  @override
  String toString() => 'ChatFailure($kind, $code)';
}

class ChatMessage {
  /// Server id; null until the server has stored it.
  final String? id;
  final String? clientMessageId;
  final String roomId;
  final String senderId;
  final MessageType type;
  final String content;
  final List<ChatAttachment> attachments;
  final DateTime createdAt;
  final MessageStatus status;
  final ChatFailure? failure;

  /// 0..1 while an attachment uploads.
  final double? uploadProgress;

  /// Local bytes for an image that is still uploading (never persisted).
  final Uint8List? localBytes;

  const ChatMessage({
    this.id,
    this.clientMessageId,
    required this.roomId,
    required this.senderId,
    required this.type,
    this.content = '',
    this.attachments = const [],
    required this.createdAt,
    this.status = MessageStatus.sent,
    this.failure,
    this.uploadProgress,
    this.localBytes,
  });

  /// Stable identity for de-duplication: a pending message and its server echo
  /// share `clientMessageId`; stored messages share `id`.
  String get key => clientMessageId != null ? 'c:$clientMessageId' : 'i:$id';

  bool isMine(String? myUserId) => myUserId != null && senderId == myUserId;

  bool get isPending => status == MessageStatus.sending;

  ChatAttachment? get firstAttachment =>
      attachments.isEmpty ? null : attachments.first;

  ChatMessage copyWith({
    String? id,
    MessageStatus? status,
    ChatFailure? failure,
    bool clearFailure = false,
    double? uploadProgress,
    bool clearProgress = false,
    List<ChatAttachment>? attachments,
    DateTime? createdAt,
    Uint8List? localBytes,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        clientMessageId: clientMessageId,
        roomId: roomId,
        senderId: senderId,
        type: type,
        content: content,
        attachments: attachments ?? this.attachments,
        createdAt: createdAt ?? this.createdAt,
        status: status ?? this.status,
        failure: clearFailure ? null : (failure ?? this.failure),
        uploadProgress:
            clearProgress ? null : (uploadProgress ?? this.uploadProgress),
        localBytes: localBytes ?? this.localBytes,
      );

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: _asStringOrNull(j['_id'] ?? j['id']),
        clientMessageId: _asStringOrNull(j['clientMessageId']),
        roomId: (j['roomId'] ?? '').toString(),
        senderId:
            (j['senderId'] is Map ? j['senderId']['_id'] : j['senderId'] ?? '')
                .toString(),
        type: MessageTypeX.parse(j['type']),
        content: (j['content'] ?? '').toString(),
        attachments: (j['attachments'] is List)
            ? (j['attachments'] as List)
                .whereType<Map>()
                .map((a) =>
                    ChatAttachment.fromJson(Map<String, dynamic>.from(a)))
                .toList()
            : const [],
        createdAt: _parseDate(j['createdAt']) ?? DateTime.now(),
        status: j['isRead'] == true ? MessageStatus.read : MessageStatus.sent,
      );

  /// Only what survives an app restart (used for cached pages and the outbox).
  Map<String, dynamic> toJson() => {
        '_id': id,
        'clientMessageId': clientMessageId,
        'roomId': roomId,
        'senderId': senderId,
        'type': type.wire,
        'content': content,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'createdAt': createdAt.toUtc().toIso8601String(),
        'isRead': status == MessageStatus.read,
        'localStatus': status.name,
        if (failure != null) 'failureCode': failure!.code ?? failure!.kind.name,
      };

  factory ChatMessage.fromCacheJson(Map<String, dynamic> j) {
    final base = ChatMessage.fromJson(j);
    final local = j['localStatus'];
    final status = MessageStatus.values.firstWhere(
      (s) => s.name == local,
      orElse: () => base.status,
    );
    // A message that was mid-send when the app died is failed, not sending.
    final fixed =
        status == MessageStatus.sending ? MessageStatus.failed : status;
    return base.copyWith(
      status: fixed,
      failure: fixed == MessageStatus.failed
          ? const ChatFailure(ChatFailureKind.offline)
          : null,
    );
  }
}

class ChatMessagePage {
  /// Newest first.
  final List<ChatMessage> messages;
  final String? nextCursor;
  final bool hasMore;
  const ChatMessagePage(this.messages, this.nextCursor, this.hasMore);
}

class ReadReceipt {
  final String roomId;
  final String userId;
  final DateTime readAt;
  const ReadReceipt(this.roomId, this.userId, this.readAt);
}

enum ChatConnectionStatus {
  connecting,
  online,
  reconnecting,
  offline,
  authFailed,
  suspended
}

/// Presigned upload returned by `POST /chats/rooms/:roomId/uploads`.
class ChatUploadTicket {
  final String uploadUrl;
  final Map<String, String> headers;
  final String url;

  const ChatUploadTicket(this.uploadUrl, this.headers, this.url);

  factory ChatUploadTicket.fromJson(Map<String, dynamic> j) => ChatUploadTicket(
        j['uploadUrl'].toString(),
        (j['headers'] as Map? ?? const {})
            .map((k, v) => MapEntry(k.toString(), v.toString())),
        j['url'].toString(),
      );
}

/// Merge [incoming] into [current] (both newest-first), de-duplicating by
/// server id and by clientMessageId so optimistic bubbles are replaced by their
/// server copies instead of doubling (audit F-01/F-09 companion).
List<ChatMessage> mergeMessages(
    List<ChatMessage> current, Iterable<ChatMessage> incoming) {
  final byId = <String, int>{};
  final byClient = <String, int>{};
  final out = List<ChatMessage>.of(current);
  for (var i = 0; i < out.length; i++) {
    final m = out[i];
    if (m.id != null) byId[m.id!] = i;
    if (m.clientMessageId != null) byClient[m.clientMessageId!] = i;
  }
  for (final m in incoming) {
    final idx = (m.id != null ? byId[m.id!] : null) ??
        (m.clientMessageId != null ? byClient[m.clientMessageId!] : null);
    if (idx != null) {
      final existing = out[idx];
      // Never downgrade a read status to sent when an older copy arrives.
      final status = existing.status == MessageStatus.read &&
              m.status == MessageStatus.sent
          ? MessageStatus.read
          : m.status;
      out[idx] = m.copyWith(status: status, localBytes: existing.localBytes);
    } else {
      out.add(m);
      final i = out.length - 1;
      if (m.id != null) byId[m.id!] = i;
      if (m.clientMessageId != null) byClient[m.clientMessageId!] = i;
    }
  }
  out.sort((a, b) {
    // Pending/failed messages always sit at the newest end.
    final ap = a.id == null ? 1 : 0;
    final bp = b.id == null ? 1 : 0;
    if (ap != bp) return bp - ap;
    final t = b.createdAt.compareTo(a.createdAt);
    if (t != 0) return t;
    return (b.id ?? '').compareTo(a.id ?? '');
  });
  return out;
}
