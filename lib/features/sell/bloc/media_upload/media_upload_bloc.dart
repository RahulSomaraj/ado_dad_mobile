import 'dart:async';
import 'dart:typed_data';

import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'media_upload_event.dart';
part 'media_upload_state.dart';
part 'media_upload_bloc.freezed.dart';

/// Owns the photos/video of an ad while it is being created or edited.
///
/// Uploads start the moment a file is added (max [_maxConcurrent] at a time),
/// so by the time the seller reaches "Post" the S3 URLs are already available
/// and posting is a single API call.
class MediaUploadBloc extends Bloc<MediaUploadEvent, MediaUploadState> {
  final AddRepository repository;

  static const int _maxConcurrent = 3;
  int _active = 0;
  final List<String> _queue = [];
  int _idSeed = 0;

  MediaUploadBloc({required this.repository, int maxImages = 10})
      : super(MediaUploadState(maxImages: maxImages)) {
    on<MediaUploadEvent>(_onEvent);
  }

  Future<void> _onEvent(
      MediaUploadEvent event, Emitter<MediaUploadState> emit) async {
    await event.map(
      imagesAdded: (e) => _onImagesAdded(e, emit),
      imageRemoved: (e) => _onImageRemoved(e, emit),
      imageMoved: (e) => _onImageMoved(e, emit),
      coverSet: (e) => _onCoverSet(e, emit),
      retryRequested: (e) => _onRetryRequested(e, emit),
      videoAdded: (e) => _onVideoAdded(e, emit),
      videoRemoved: (e) => _onVideoRemoved(e, emit),
      seeded: (e) => _onSeeded(e, emit),
      uploadResultReceived: (e) => _onUploadResult(e, emit),
      cleared: (e) => _onCleared(e, emit),
    );
  }

  String _nextId() => 'm${DateTime.now().microsecondsSinceEpoch}_${_idSeed++}';

  // ---------------------------------------------------------------- images

  Future<void> _onImagesAdded(
      _ImagesAdded e, Emitter<MediaUploadState> emit) async {
    final room = state.maxImages - state.images.length;
    if (room <= 0) return;
    final newItems = e.files
        .take(room)
        .map((bytes) => MediaItem(localId: _nextId(), bytes: bytes))
        .toList();
    emit(state.copyWith(images: [...state.images, ...newItems]));
    for (final item in newItems) {
      _queue.add(item.localId);
    }
    _pump();
  }

  Future<void> _onImageRemoved(
      _ImageRemoved e, Emitter<MediaUploadState> emit) async {
    _queue.remove(e.localId);
    emit(state.copyWith(
      images: state.images.where((i) => i.localId != e.localId).toList(),
    ));
  }

  Future<void> _onImageMoved(
      _ImageMoved e, Emitter<MediaUploadState> emit) async {
    final list = [...state.images];
    if (e.oldIndex < 0 || e.oldIndex >= list.length) return;
    var newIndex = e.newIndex.clamp(0, list.length - 1);
    final item = list.removeAt(e.oldIndex);
    list.insert(newIndex, item);
    emit(state.copyWith(images: list));
  }

  Future<void> _onCoverSet(_CoverSet e, Emitter<MediaUploadState> emit) async {
    final idx = state.images.indexWhere((i) => i.localId == e.localId);
    if (idx <= 0) return;
    final list = [...state.images];
    final item = list.removeAt(idx);
    list.insert(0, item);
    emit(state.copyWith(images: list));
  }

  Future<void> _onRetryRequested(
      _RetryRequested e, Emitter<MediaUploadState> emit) async {
    // An item without bytes (e.g. seeded from an existing URL) can never be
    // re-uploaded, so a retry is a no-op.
    final target = _find(e.localId);
    if (target == null || target.bytes == null) return;
    if (state.video?.localId == e.localId) {
      emit(state.copyWith(
          video: state.video!.copyWith(status: MediaUploadStatus.queued)));
      _queue.add(e.localId);
    } else {
      emit(state.copyWith(
        images: state.images
            .map((i) => i.localId == e.localId
                ? i.copyWith(status: MediaUploadStatus.queued)
                : i)
            .toList(),
      ));
      _queue.add(e.localId);
    }
    _pump();
  }

  // ----------------------------------------------------------------- video

  Future<void> _onVideoAdded(
      _VideoAdded e, Emitter<MediaUploadState> emit) async {
    if (state.video != null) _queue.remove(state.video!.localId);
    final item = MediaItem(
      localId: _nextId(),
      bytes: e.file,
      fileName: e.fileName,
      isVideo: true,
    );
    emit(state.copyWith(video: item));
    _queue.add(item.localId);
    _pump();
  }

  Future<void> _onVideoRemoved(
      _VideoRemoved e, Emitter<MediaUploadState> emit) async {
    if (state.video != null) _queue.remove(state.video!.localId);
    emit(state.copyWith(video: null));
  }

  // ------------------------------------------------------------ edit seed

  /// Used by the edit forms: existing S3 URLs are already "done".
  Future<void> _onSeeded(_Seeded e, Emitter<MediaUploadState> emit) async {
    final images = e.imageUrls
        .map((url) => MediaItem(
              localId: _nextId(),
              url: url,
              status: MediaUploadStatus.done,
            ))
        .toList();
    final video = (e.videoUrl == null || e.videoUrl!.isEmpty)
        ? null
        : MediaItem(
            localId: _nextId(),
            url: e.videoUrl,
            status: MediaUploadStatus.done,
            isVideo: true,
          );
    emit(state.copyWith(images: images, video: video));
  }

  Future<void> _onCleared(_Cleared e, Emitter<MediaUploadState> emit) async {
    _queue.clear();
    emit(MediaUploadState(maxImages: state.maxImages));
  }

  // --------------------------------------------------------------- upload

  void _pump() {
    while (_active < _maxConcurrent && _queue.isNotEmpty) {
      final id = _queue.removeAt(0);
      final item = _find(id);
      if (item == null) continue;
      if (item.bytes == null) {
        // Nothing to upload: mark it failed instead of leaving it queued.
        add(MediaUploadEvent.uploadResultReceived(localId: id, url: null));
        continue;
      }
      _active++;
      add(MediaUploadEvent.uploadResultReceived(
          localId: id, url: null, started: true));
      unawaited(_upload(item));
    }
  }

  Future<void> _upload(MediaItem item) async {
    String? url;
    try {
      url = item.isVideo
          ? await repository.uploadVideoToS3(item.bytes!)
          : await repository.uploadImageToS3(item.bytes!);
    } catch (err) {
      debugPrint('Media upload failed for ${item.localId}: $err');
      url = null;
    }
    _active--;
    if (isClosed) return;
    add(MediaUploadEvent.uploadResultReceived(localId: item.localId, url: url));
    _pump();
  }

  Future<void> _onUploadResult(
      _UploadResultReceived e, Emitter<MediaUploadState> emit) async {
    final MediaUploadStatus status = e.started
        ? MediaUploadStatus.uploading
        : (e.url != null && e.url!.isNotEmpty)
            ? MediaUploadStatus.done
            : MediaUploadStatus.failed;

    MediaItem apply(MediaItem i) => i.localId == e.localId
        ? i.copyWith(status: status, url: e.started ? i.url : e.url)
        : i;

    emit(state.copyWith(
      images: state.images.map(apply).toList(),
      video: state.video == null ? null : apply(state.video!),
    ));
  }

  MediaItem? _find(String id) {
    if (state.video?.localId == id) return state.video;
    for (final i in state.images) {
      if (i.localId == id) return i;
    }
    return null;
  }
}
