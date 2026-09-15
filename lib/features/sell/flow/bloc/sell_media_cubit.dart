import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mime/mime.dart';

import '../data/sell_draft_store.dart';
import '../data/sell_media_repository.dart';
import '../domain/sell_format.dart';
import '../domain/sell_models.dart';

class SellMediaState {
  final List<SellMediaItem> items;
  final int maxPhotos;
  final bool online;

  const SellMediaState({
    this.items = const [],
    this.maxPhotos = 20,
    this.online = true,
  });

  List<SellMediaItem> get photos => items.where((i) => !i.isVideo).toList();
  SellMediaItem? get video {
    for (final i in items) {
      if (i.isVideo) return i;
    }
    return null;
  }

  int get photoCount => photos.length;
  int get uploadingCount => items.where((i) => i.isInFlight).length;
  int get failedCount => items.where((i) => i.isFailed).length;
  int get pausedCount => items.where((i) => i.status == SellMediaStatus.paused).length;
  bool get canAddPhoto => photoCount < maxPhotos;

  /// Every picked file has a mediaId — safe to post.
  bool get allDone => items.every((i) => i.isDone);

  SellMediaState copyWith({List<SellMediaItem>? items, int? maxPhotos, bool? online}) =>
      SellMediaState(
        items: items ?? this.items,
        maxPhotos: maxPhotos ?? this.maxPhotos,
        online: online ?? this.online,
      );
}

/// Owns photos/video while an ad is drafted. Uploads start on pick (3 at a
/// time), retry up to 3 times with backoff, pause while offline and resume
/// on their own.
class SellMediaCubit extends Cubit<SellMediaState> {
  SellMediaCubit({
    required this.draftId,
    required int maxPhotos,
    SellMediaRepository? repository,
    SellDraftStore? store,
    this.onChanged,
  })  : _repo = repository ?? SellMediaRepository(),
        _store = store ?? SellDraftStore.instance,
        super(SellMediaState(maxPhotos: maxPhotos));

  final String draftId;
  final SellMediaRepository _repo;
  final SellDraftStore _store;

  /// Called after any change worth persisting (draft autosave).
  final void Function()? onChanged;

  static const int _maxConcurrent = 3;
  static const int _maxAttempts = 3;

  final Map<String, CancelToken> _tokens = {};
  final Map<String, int> _attempts = {};
  int _seed = 0;

  String _newId() => 'm${DateTime.now().microsecondsSinceEpoch}_${_seed++}';

  void setMaxPhotos(int max) {
    if (max != state.maxPhotos) emit(state.copyWith(maxPhotos: max));
  }

  /// Restores items from a draft; anything without a mediaId is re-uploaded
  /// from its local copy (temp media expires on the server after 72 h).
  void seed(List<SellMediaItem> items) {
    emit(state.copyWith(items: items));
    _pump();
  }

  Future<void> addPhotos(List<String> paths) async {
    final room = state.maxPhotos - state.photoCount;
    if (room <= 0 || paths.isEmpty) return;
    final added = <SellMediaItem>[];
    for (final path in paths.take(room)) {
      final id = _newId();
      final local = await _store.adoptFile(draftId, path, id);
      int size = 0;
      try {
        size = await File(local).length();
      } catch (_) {}
      added.add(SellMediaItem(
        localId: id,
        localPath: local,
        contentType: lookupMimeType(local) ?? 'image/jpeg',
        bytes: size,
      ));
    }
    if (isClosed) return;
    // Re-check: another pick may have landed while files were copied.
    final left = state.maxPhotos - state.photoCount;
    if (left <= 0) return;
    final video = state.video;
    final photos = [...state.photos, ...added.take(left)];
    emit(state.copyWith(items: [...photos, if (video != null) video]));
    onChanged?.call();
    _pump();
  }

  Future<void> setVideo(String path) async {
    final old = state.video;
    if (old != null) _cancel(old.localId);
    final id = _newId();
    final local = await _store.adoptFile(draftId, path, id);
    int size = 0;
    try {
      size = await File(local).length();
    } catch (_) {}
    if (isClosed) return;
    final item = SellMediaItem(
      localId: id,
      localPath: local,
      isVideo: true,
      contentType: lookupMimeType(local) ?? 'video/mp4',
      bytes: size,
    );
    emit(state.copyWith(items: [...state.photos, item]));
    onChanged?.call();
    _pump();
  }

  void remove(String localId) {
    _cancel(localId);
    emit(state.copyWith(items: state.items.where((i) => i.localId != localId).toList()));
    onChanged?.call();
    _pump();
  }

  void movePhoto(int oldIndex, int newIndex) {
    final photos = state.photos;
    if (oldIndex < 0 || oldIndex >= photos.length) return;
    final item = photos.removeAt(oldIndex);
    photos.insert(newIndex.clamp(0, photos.length), item);
    final video = state.video;
    emit(state.copyWith(items: [...photos, if (video != null) video]));
    onChanged?.call();
  }

  void setCover(String localId) {
    final photos = state.photos;
    final idx = photos.indexWhere((p) => p.localId == localId);
    if (idx <= 0) return;
    movePhoto(idx, 0);
  }

  void retry(String localId) {
    _attempts.remove(localId);
    _update(localId, (i) => i.copyWith(status: SellMediaStatus.queued, progress: 0, clearError: true));
    _pump();
  }

  void retryAll() {
    for (final i in state.items.where((i) => i.isFailed || i.status == SellMediaStatus.paused)) {
      _attempts.remove(i.localId);
      _update(i.localId, (x) => x.copyWith(status: SellMediaStatus.queued, progress: 0, clearError: true));
    }
    _pump();
  }

  /// After the server rejects `data.mediaIds` (expired or already attached),
  /// upload every file again from its local copy.
  void reuploadAll() {
    for (final t in _tokens.values) {
      t.cancel('reset');
    }
    _tokens.clear();
    _attempts.clear();
    emit(state.copyWith(items: [
      for (final i in state.items)
        i.copyWith(status: SellMediaStatus.queued, progress: 0, clearRemote: true, clearError: true),
    ]));
    onChanged?.call();
    _pump();
  }

  void setOnline(bool online) {
    if (online == state.online) return;
    if (!online) {
      final items = state.items
          .map((i) => i.isInFlight ? i.copyWith(status: SellMediaStatus.paused) : i)
          .toList();
      for (final t in _tokens.values) {
        t.cancel('offline');
      }
      _tokens.clear();
      emit(state.copyWith(online: false, items: items));
    } else {
      final items = state.items
          .map((i) => i.status == SellMediaStatus.paused
              ? i.copyWith(status: SellMediaStatus.queued, progress: 0)
              : i)
          .toList();
      emit(state.copyWith(online: true, items: items));
      _pump();
    }
  }

  // ------------------------------------------------------------------ queue

  void _pump() {
    if (isClosed || !state.online) return;
    var active = _tokens.length;
    for (final item in state.items) {
      if (active >= _maxConcurrent) break;
      if (item.status != SellMediaStatus.queued || _tokens.containsKey(item.localId)) continue;
      active++;
      unawaited(_upload(item));
    }
  }

  Future<void> _upload(SellMediaItem item) async {
    final token = CancelToken();
    _tokens[item.localId] = token;
    _update(item.localId, (i) => i.copyWith(status: SellMediaStatus.uploading, progress: 0.02));
    try {
      final result = await _repo.upload(
        path: item.localPath,
        contentType: item.contentType,
        isVideo: item.isVideo,
        cancelToken: token,
        onProgress: (p) {
          if (isClosed || !identical(_tokens[item.localId], token)) return;
          _update(item.localId, (i) => i.status == SellMediaStatus.uploading ? i.copyWith(progress: p) : i);
        },
      );
      _release(item.localId, token);
      if (isClosed || token.isCancelled) return;
      _attempts.remove(item.localId);
      _update(
        item.localId,
        (i) => i.copyWith(
          status: SellMediaStatus.done,
          progress: 1,
          mediaId: result.mediaId,
          url: result.url,
          uploadedAt: DateTime.now(),
          clearError: true,
        ),
      );
      onChanged?.call();
    } on MediaRejected catch (e) {
      _release(item.localId, token);
      if (isClosed || token.isCancelled) return;
      _update(item.localId, (i) => i.copyWith(status: SellMediaStatus.failed, error: e.message));
    } on MediaThrottled catch (e) {
      _release(item.localId, token);
      if (isClosed || token.isCancelled) return;
      _update(item.localId, (i) => i.copyWith(status: SellMediaStatus.paused));
      await Future<void>.delayed(e.wait);
      if (isClosed || !_exists(item.localId)) return;
      _update(item.localId, (i) => i.status == SellMediaStatus.paused ? i.copyWith(status: SellMediaStatus.queued) : i);
    } catch (e) {
      _release(item.localId, token);
      if (isClosed) return;
      if ((e is DioException && CancelToken.isCancel(e)) || token.isCancelled) {
        // Removed, reset, or paused because the network dropped.
      } else if (!state.online) {
        _update(item.localId, (i) => i.copyWith(status: SellMediaStatus.paused));
      } else {
        final attempts = (_attempts[item.localId] ?? 0) + 1;
        _attempts[item.localId] = attempts;
        if (attempts < _maxAttempts && _exists(item.localId)) {
          await Future<void>.delayed(Duration(seconds: 2 << (attempts - 1)));
          if (isClosed || !_exists(item.localId)) return;
          _update(
            item.localId,
            (i) => i.status == SellMediaStatus.uploading && !_tokens.containsKey(i.localId)
                ? i.copyWith(status: SellMediaStatus.queued)
                : i,
          );
        } else {
          _update(item.localId, (i) => i.copyWith(status: SellMediaStatus.failed, error: 'Upload didn’t finish'));
        }
      }
    }
    _pump();
  }

  /// Removes [t] only if it is still the live token for [id] — a newer
  /// upload of the same item may have replaced it (connectivity flap).
  void _release(String id, CancelToken t) {
    if (identical(_tokens[id], t)) _tokens.remove(id);
  }

  bool _exists(String id) => state.items.any((i) => i.localId == id);

  void _cancel(String localId) {
    _tokens.remove(localId)?.cancel('removed');
    _attempts.remove(localId);
  }

  void _update(String localId, SellMediaItem Function(SellMediaItem) f) {
    if (isClosed) return;
    var changed = false;
    final items = state.items.map((i) {
      if (i.localId != localId) return i;
      changed = true;
      return f(i);
    }).toList();
    if (changed) emit(state.copyWith(items: items));
  }

  @override
  Future<void> close() {
    for (final t in _tokens.values) {
      t.cancel('closed');
    }
    _tokens.clear();
    return super.close();
  }

  /// Short status line for the action bar: "3 photos · 1 uploading".
  static String summary(SellMediaState s) {
    final n = s.photoCount;
    final base = n == 1 ? '1 photo' : '$n photos';
    if (!s.online && s.pausedCount + s.uploadingCount > 0) {
      return '$base · ${s.pausedCount + s.uploadingCount} waiting';
    }
    if (s.failedCount > 0) return '$base · ${s.failedCount} failed';
    if (s.uploadingCount > 0) return '$base · ${s.uploadingCount} uploading';
    return base;
  }

  /// Bytes left to upload, for the "1.2 MB of 1.6 MB" card.
  static String bytesLabel(int bytes) {
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${SellFormat.indianGroup((bytes / 1024).round())} KB';
  }
}
