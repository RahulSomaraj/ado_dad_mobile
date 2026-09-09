part of 'media_upload_bloc.dart';

enum MediaUploadStatus { queued, uploading, done, failed }

@freezed
class MediaItem with _$MediaItem {
  const MediaItem._();
  const factory MediaItem({
    required String localId,
    Uint8List? bytes,
    String? url,
    String? fileName,
    @Default(false) bool isVideo,
    @Default(MediaUploadStatus.queued) MediaUploadStatus status,
  }) = _MediaItem;

  bool get isDone => status == MediaUploadStatus.done && url != null;
  bool get isFailed => status == MediaUploadStatus.failed;
  bool get isInFlight =>
      status == MediaUploadStatus.queued ||
      status == MediaUploadStatus.uploading;
}

@freezed
class MediaUploadState with _$MediaUploadState {
  const MediaUploadState._();
  const factory MediaUploadState({
    @Default(<MediaItem>[]) List<MediaItem> images,
    MediaItem? video,
    @Default(10) int maxImages,
  }) = _MediaUploadState;

  bool get hasImages => images.isNotEmpty;
  bool get canAddMore => images.length < maxImages;
  int get uploadedCount => images.where((i) => i.isDone).length;
  int get pendingCount =>
      images.where((i) => i.isInFlight).length +
      ((video?.isInFlight ?? false) ? 1 : 0);
  bool get hasFailed =>
      images.any((i) => i.isFailed) || (video?.isFailed ?? false);
  bool get isUploading =>
      images.any((i) => i.isInFlight) || (video?.isInFlight ?? false);

  /// True when every picked file has a URL — safe to post the ad.
  bool get allDone =>
      images.every((i) => i.isDone) && (video == null || video!.isDone);

  /// URLs in display order; index 0 is the cover photo.
  List<String> get imageUrls =>
      images.where((i) => i.isDone).map((i) => i.url!).toList();
  String? get videoUrl => video?.isDone == true ? video!.url : null;
}
