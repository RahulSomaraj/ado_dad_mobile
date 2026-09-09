part of 'media_upload_bloc.dart';

@freezed
class MediaUploadEvent with _$MediaUploadEvent {
  /// Seller picked one or more images (camera or gallery).
  const factory MediaUploadEvent.imagesAdded(List<Uint8List> files) =
      _ImagesAdded;
  const factory MediaUploadEvent.imageRemoved(String localId) = _ImageRemoved;
  const factory MediaUploadEvent.imageMoved(
      {required int oldIndex, required int newIndex}) = _ImageMoved;

  /// Moves the image to index 0 — the first image is the cover photo.
  const factory MediaUploadEvent.coverSet(String localId) = _CoverSet;
  const factory MediaUploadEvent.retryRequested(String localId) =
      _RetryRequested;

  const factory MediaUploadEvent.videoAdded(
      {required Uint8List file, required String fileName}) = _VideoAdded;
  const factory MediaUploadEvent.videoRemoved() = _VideoRemoved;

  /// Pre-fill with already uploaded URLs (edit flow).
  const factory MediaUploadEvent.seeded(
      {required List<String> imageUrls, String? videoUrl}) = _Seeded;

  const factory MediaUploadEvent.cleared() = _Cleared;

  /// Internal: dispatched by the bloc itself when an upload starts / finishes.
  const factory MediaUploadEvent.uploadResultReceived({
    required String localId,
    required String? url,
    @Default(false) bool started,
  }) = _UploadResultReceived;
}
