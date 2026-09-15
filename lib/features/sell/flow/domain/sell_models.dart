import 'sell_category.dart';

/// Keys of [SellDraft.values]. One flat map keeps drafts, validation and the
/// payload mapper on the same vocabulary.
class SellKeys {
  SellKeys._();
  // vehicle
  static const brandId = 'brandId';
  static const brandName = 'brandName';
  static const modelId = 'modelId';
  static const modelName = 'modelName';
  static const variantId = 'variantId'; // '' = "Not sure"
  static const variantName = 'variantName';
  static const year = 'year';
  static const mileage = 'mileage';
  static const fuelTypeId = 'fuelTypeId';
  static const transmissionTypeId = 'transmissionTypeId';
  static const color = 'color';
  static const ownerCount = 'ownerCount';
  static const hasInsurance = 'hasInsurance';
  static const hasRcBook = 'hasRcBook';
  static const features = 'features';
  // commercial
  static const commercialType = 'commercialType';
  static const bodyType = 'bodyType';
  static const payloadCapacity = 'payloadCapacity';
  static const payloadUnit = 'payloadUnit';
  static const axleCount = 'axleCount';
  static const seatingCapacity = 'seatingCapacity';
  static const hasFitness = 'hasFitness';
  static const hasPermit = 'hasPermit';
  // property
  static const listingType = 'listingType';
  static const propertyType = 'propertyType';
  static const bedrooms = 'bedrooms';
  static const bathrooms = 'bathrooms';
  static const builtArea = 'builtArea';
  static const builtUnit = 'builtUnit';
  static const landArea = 'landArea';
  static const landUnit = 'landUnit';
  static const floor = 'floor';
  static const furnishing = 'furnishing';
  static const hasParking = 'hasParking';
  static const hasGarden = 'hasGarden';
  // price & place
  static const price = 'price';
  static const location = 'location';
  static const latitude = 'latitude';
  static const longitude = 'longitude';
  static const title = 'title';
  static const titleEdited = 'titleEdited';
  static const description = 'description';
  // photos (validation key only)
  static const photos = 'photos';
}

enum SellMediaStatus { queued, uploading, done, failed, paused }

/// One picked photo or the video. [localPath] is a copy inside the draft
/// folder, so a draft survives the image picker's cache being cleared.
class SellMediaItem {
  final String localId;
  final String localPath;
  final bool isVideo;
  final String contentType;
  final int bytes;
  final SellMediaStatus status;
  final double progress; // 0..1
  final String? mediaId;
  final String? url;
  final String? error;
  final DateTime? uploadedAt;

  const SellMediaItem({
    required this.localId,
    required this.localPath,
    required this.contentType,
    required this.bytes,
    this.isVideo = false,
    this.status = SellMediaStatus.queued,
    this.progress = 0,
    this.mediaId,
    this.url,
    this.error,
    this.uploadedAt,
  });

  bool get isDone => status == SellMediaStatus.done && mediaId != null;
  bool get isFailed => status == SellMediaStatus.failed;
  bool get isInFlight =>
      status == SellMediaStatus.queued || status == SellMediaStatus.uploading;

  SellMediaItem copyWith({
    SellMediaStatus? status,
    double? progress,
    String? mediaId,
    String? url,
    String? error,
    DateTime? uploadedAt,
    bool clearError = false,
    bool clearRemote = false,
  }) =>
      SellMediaItem(
        localId: localId,
        localPath: localPath,
        isVideo: isVideo,
        contentType: contentType,
        bytes: bytes,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        mediaId: clearRemote ? null : (mediaId ?? this.mediaId),
        url: clearRemote ? null : (url ?? this.url),
        error: clearError ? null : (error ?? this.error),
        uploadedAt: clearRemote ? null : (uploadedAt ?? this.uploadedAt),
      );

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'localPath': localPath,
        'isVideo': isVideo,
        'contentType': contentType,
        'bytes': bytes,
        'mediaId': isDone ? mediaId : null,
        'url': isDone ? url : null,
        'uploadedAt': isDone ? uploadedAt?.toIso8601String() : null,
      };

  /// Server temp media expires after 72 h; anything older than 48 h is
  /// re-uploaded from the local copy on resume.
  factory SellMediaItem.fromJson(Map<String, dynamic> j) {
    final at = DateTime.tryParse('${j['uploadedAt']}');
    final fresh = j['mediaId'] != null &&
        at != null &&
        DateTime.now().difference(at) < const Duration(hours: 48);
    return SellMediaItem(
      localId: j['localId'] as String,
      localPath: j['localPath'] as String,
      isVideo: j['isVideo'] == true,
      contentType: (j['contentType'] ?? 'image/jpeg') as String,
      bytes: (j['bytes'] as num?)?.toInt() ?? 0,
      mediaId: fresh ? j['mediaId'] as String : null,
      url: fresh ? j['url'] as String? : null,
      uploadedAt: fresh ? at : null,
      status: fresh ? SellMediaStatus.done : SellMediaStatus.queued,
      progress: fresh ? 1 : 0,
    );
  }
}

/// A locally saved, resumable ad.
class SellDraft {
  static const int schemaVersion = 1;

  final String id;
  final SellCategory category;
  final SellStep step;
  final Map<String, dynamic> values;
  final List<SellMediaItem> media;
  final String idempotencyKey;
  final DateTime updatedAt;

  const SellDraft({
    required this.id,
    required this.category,
    required this.step,
    required this.values,
    required this.media,
    required this.idempotencyKey,
    required this.updatedAt,
  });

  List<SellMediaItem> get photos => media.where((m) => !m.isVideo).toList();

  /// "2019 Maruti Suzuki Swift" / "3 BHK House" / "Property".
  String get headline {
    String? s(String k) {
      final v = values[k];
      return (v == null || '$v'.trim().isEmpty) ? null : '$v'.trim();
    }

    if (category.isVehicle) {
      final parts = [s(SellKeys.year), s(SellKeys.brandName), s(SellKeys.modelName)]
          .whereType<String>()
          .toList();
      return parts.isEmpty ? 'Untitled ${category.noun}' : parts.join(' ');
    }
    final type = s(SellKeys.propertyType);
    final beds = s(SellKeys.bedrooms);
    if (type == null) return 'Untitled property';
    final label = type[0].toUpperCase() + type.substring(1);
    return beds != null ? '$beds BHK $label' : label;
  }

  Map<String, dynamic> toJson() => {
        'v': schemaVersion,
        'id': id,
        'category': category.slug,
        'step': step.name,
        'values': values,
        'media': media.map((m) => m.toJson()).toList(),
        'idempotencyKey': idempotencyKey,
        'updatedAt': updatedAt.toIso8601String(),
      };

  static SellDraft? fromJson(Map<String, dynamic> j) {
    final category = SellCategory.fromSlug(j['category'] as String?);
    if (category == null) return null;
    final step = SellStep.values.firstWhere(
      (s) => s.name == j['step'],
      orElse: () => SellStep.photos,
    );
    return SellDraft(
      id: j['id'] as String,
      category: category,
      step: step,
      values: Map<String, dynamic>.from((j['values'] as Map?) ?? const {}),
      media: ((j['media'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => SellMediaItem.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      idempotencyKey: j['idempotencyKey'] as String,
      updatedAt: DateTime.tryParse('${j['updatedAt']}') ?? DateTime.now(),
    );
  }
}

/// Why posting failed. Drives the Review banner (W09) and reauth sheet (W14).
sealed class CreateAdFailure {
  const CreateAdFailure();
}

class ValidationFailure extends CreateAdFailure {
  /// Local keys ([SellKeys]) → message.
  final Map<String, String> fields;
  final String message;
  const ValidationFailure(this.fields, this.message);
}

class NetworkFailure extends CreateAdFailure {
  const NetworkFailure();
}

class ServerFailure extends CreateAdFailure {
  final String message;

  /// The idempotency key was already used with a different body.
  final bool keyReused;
  const ServerFailure(this.message, {this.keyReused = false});
}

class SuspendedFailure extends CreateAdFailure {
  final String message;
  const SuspendedFailure(this.message);
}

class AuthFailure extends CreateAdFailure {
  const AuthFailure();
}

class InProgressFailure extends CreateAdFailure {
  const InProgressFailure();
}

class RateLimitedFailure extends CreateAdFailure {
  const RateLimitedFailure();
}

class CreatedAd {
  final String id;
  final String status;
  const CreatedAd(this.id, this.status);
}
