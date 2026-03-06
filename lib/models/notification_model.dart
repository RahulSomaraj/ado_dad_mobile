/// Media attachment for a notification (image, video, etc.).
class NotificationMedia {
  final String type; // e.g. "IMAGE", "VIDEO", "AUDIO"
  final String url;

  NotificationMedia({required this.type, required this.url});

  factory NotificationMedia.fromJson(Map<String, dynamic> json) {
    return NotificationMedia(
      type: json['type'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'type': type, 'url': url};
}

/// Optional inner payload (screen, type, entityId).
class NotificationPayloadData {
  final String? type;
  final String? screen;
  final String? entityId;

  NotificationPayloadData({this.type, this.screen, this.entityId});

  factory NotificationPayloadData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return NotificationPayloadData();
    return NotificationPayloadData(
      type: json['type'] as String?,
      screen: json['screen'] as String?,
      entityId: json['entityId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (type != null) 'type': type,
        if (screen != null) 'screen': screen,
        if (entityId != null) 'entityId': entityId,
      };
}

/// Nested "data" object inside each notification item.
class NotificationData {
  final String targetType;
  final String priority;
  final String title;
  final String body;
  final NotificationMedia? media;
  final NotificationPayloadData? data;

  NotificationData({
    required this.targetType,
    required this.priority,
    required this.title,
    required this.body,
    this.media,
    this.data,
  });

  factory NotificationData.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return NotificationData(
        targetType: '',
        priority: '',
        title: '',
        body: '',
      );
    }
    final mediaJson = json['media'];
    final dataJson = json['data'];
    return NotificationData(
      targetType: json['targetType'] as String? ?? '',
      priority: json['priority'] as String? ?? 'NORMAL',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      media: mediaJson is Map<String, dynamic>
          ? NotificationMedia.fromJson(mediaJson)
          : null,
      data: dataJson is Map<String, dynamic>
          ? NotificationPayloadData.fromJson(dataJson)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'targetType': targetType,
        'priority': priority,
        'title': title,
        'body': body,
        if (media != null) 'media': media!.toJson(),
        if (data != null) 'data': data!.toJson(),
      };

  bool get hasMedia => media != null && media!.url.isNotEmpty;
}

/// Single notification item from the API.
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationData data;
  final Object? response; // String (message id) or Map (error)
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    this.response,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'];
    return NotificationModel(
      id: json['_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: dataJson is Map<String, dynamic>
          ? NotificationData.fromJson(dataJson)
          : NotificationData(
              targetType: '',
              priority: '',
              title: '',
              body: '',
            ),
      response: json['response'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'title': title,
        'body': body,
        'data': data.toJson(),
        'response': response,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  bool get hasMedia => data.hasMedia;
}

/// Paginated list response from GET /notifications.
class NotificationListResponse {
  final List<NotificationModel> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  NotificationListResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'];
    return NotificationListResponse(
      data: list is List
          ? (list)
              .map((e) => NotificationModel.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList()
          : [],
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 10,
      totalPages: json['totalPages'] as int? ?? 0,
      hasNext: json['hasNext'] as bool? ?? false,
      hasPrev: json['hasPrev'] as bool? ?? false,
    );
  }
}
