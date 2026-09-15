import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../bloc/sell_flow_cubit.dart';
import '../../bloc/sell_media_cubit.dart';
import '../../domain/sell_models.dart';
import '../widgets/sell_ui.dart';

/// W02 · W03 — Step 1: photos with shot list, live upload states, video.
class PhotosStep extends StatelessWidget {
  const PhotosStep({super.key});

  static final ImagePicker _picker = ImagePicker();

  Future<void> _pickGallery(BuildContext context) async {
    final media = context.read<SellMediaCubit>();
    final room = media.state.maxPhotos - media.state.photoCount;
    if (room <= 0) return;
    try {
      final picked = await _picker.pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
        limit: room > 1 ? room : null,
        requestFullMetadata: false,
      );
      if (picked.isEmpty) return;
      await media.addPhotos(picked.map((x) => x.path).toList());
    } catch (_) {
      if (context.mounted) _toast(context, 'Couldn’t open your gallery. Check photo permission in Settings.');
    }
  }

  Future<void> _pickCamera(BuildContext context) async {
    final media = context.read<SellMediaCubit>();
    if (!media.state.canAddPhoto) return;
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
        requestFullMetadata: false,
      );
      if (picked == null) return;
      await media.addPhotos([picked.path]);
    } catch (_) {
      if (context.mounted) _toast(context, 'Couldn’t open the camera. Check camera permission in Settings.');
    }
  }

  Future<void> _pickVideo(BuildContext context) async {
    final media = context.read<SellMediaCubit>();
    final limits = context.read<SellFlowCubit>().state.config.limits;
    try {
      final picked = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: Duration(seconds: limits.maxVideoSeconds),
      );
      if (picked == null) return;
      final size = await File(picked.path).length();
      if (size > limits.maxVideoBytes) {
        if (context.mounted) {
          _toast(context, 'That video is ${SellMediaCubit.bytesLabel(size)}. Pick one under ${SellMediaCubit.bytesLabel(limits.maxVideoBytes)} (about ${limits.maxVideoSeconds} s).');
        }
        return;
      }
      await media.setVideo(picked.path);
    } catch (_) {
      if (context.mounted) _toast(context, 'Couldn’t open that video.');
    }
  }

  static void _toast(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }

  void _tileActions(BuildContext context, SellMediaItem item, int index) {
    final media = context.read<SellMediaCubit>();
    showSellSheet<void>(
      context,
      (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(SellTokens.rCard),
            child: AspectRatio(aspectRatio: 4 / 3, child: SellPhoto(localPath: item.localPath, url: item.url)),
          ),
          const SizedBox(height: 12),
          if (item.isFailed) ...[
            SellButton(label: 'Retry upload', icon: Icons.refresh_rounded, onPressed: () {
              Navigator.of(ctx).pop();
              media.retry(item.localId);
            }),
            const SizedBox(height: 8),
          ],
          if (index > 0) ...[
            SellButton(label: 'Make cover photo', kind: SellButtonKind.tonal, onPressed: () {
              Navigator.of(ctx).pop();
              media.setCover(item.localId);
            }),
            const SizedBox(height: 8),
          ],
          SellButton(label: 'Remove photo', kind: SellButtonKind.danger, onPressed: () {
            Navigator.of(ctx).pop();
            media.remove(item.localId);
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<SellFlowCubit>().state;
    final media = context.watch<SellMediaCubit>().state;
    final limits = flow.config.limits;
    final photos = media.photos;
    final shots = flow.config.shotList;
    final emptySlots = <String>[
      for (var i = photos.length; i < shots.length; i++) shots[i],
    ];
    final error = flow.errors[SellKeys.photos];
    final inFlight = media.items.where((i) => i.status == SellMediaStatus.uploading).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(SellTokens.gutter, 4, SellTokens.gutter, 24),
      children: [
        Text('Add photos buyers look for', style: SellTokens.heading),
        const SizedBox(height: 4),
        Text('Ads with ${limits.recommendedPhotos}+ photos get more calls. Up to ${limits.maxPhotos}.', style: SellTokens.caption),
        const SizedBox(height: 14),
        if (!media.online && (media.pausedCount + media.uploadingCount) > 0) ...[
          const SellBanner(
            kind: SellBannerKind.warn,
            icon: Icons.wifi_off_rounded,
            title: 'You’re offline.',
            body: 'Photos will upload when you’re back.',
          ),
          const SizedBox(height: 12),
        ] else if (media.failedCount > 0) ...[
          SellBanner(
            kind: SellBannerKind.error,
            icon: Icons.error_outline_rounded,
            title: media.failedCount == 1 ? '1 photo didn’t upload.' : '${media.failedCount} photos didn’t upload.',
            body: 'It’s still on your phone. Retry, or remove it.',
          ),
          const SizedBox(height: 12),
        ],
        if (error != null) ...[
          SellBanner(kind: SellBannerKind.error, icon: Icons.photo_camera_outlined, title: error),
          const SizedBox(height: 12),
        ],
        LayoutBuilder(builder: (context, c) {
          const gap = 8.0;
          final size = (c.maxWidth - gap * 2) / 3;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var i = 0; i < photos.length; i++)
                _DraggableTile(
                  key: ValueKey(photos[i].localId),
                  item: photos[i],
                  index: i,
                  size: size,
                  label: i == 0 ? 'Cover${shots.isNotEmpty ? ' · ${shots.first}' : ''}' : null,
                  onTap: () => _tileActions(context, photos[i], i),
                  onMove: (from, to) => context.read<SellMediaCubit>().movePhoto(from, to),
                ),
              for (final s in emptySlots.take(media.canAddPhoto ? emptySlots.length : 0))
                _SlotTile(size: size, label: s, onTap: () => _pickGallery(context)),
              if (media.canAddPhoto && emptySlots.isEmpty)
                _AddTile(size: size, onTap: () => _pickGallery(context)),
            ],
          );
        }),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SellChip(label: 'Camera', icon: Icons.photo_camera_outlined, selected: false, onTap: () => _pickCamera(context)),
            SellChip(label: 'Gallery', icon: Icons.photo_library_outlined, selected: false, onTap: () => _pickGallery(context)),
            SellChip(
              label: media.video == null ? 'Video' : 'Replace video',
              icon: Icons.videocam_outlined,
              selected: false,
              onTap: () => _pickVideo(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (photos.length > 1)
          Text('Long-press to reorder · tap a photo to make it the cover', style: SellTokens.caption),
        if (inFlight.isNotEmpty) ...[
          const SizedBox(height: 14),
          _UploadCard(items: inFlight),
        ],
        if (media.video != null) ...[
          const SizedBox(height: 14),
          _VideoRow(item: media.video!),
        ],
      ],
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({required this.items});
  final List<SellMediaItem> items;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(0, (a, i) => a + i.bytes);
    final sent = items.fold<double>(0, (a, i) => a + i.bytes * i.progress);
    final ratio = total == 0 ? 0.0 : (sent / total).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SellTokens.surface,
        borderRadius: BorderRadius.circular(SellTokens.rCard),
        border: Border.all(color: SellTokens.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(items.length == 1 ? 'Uploading 1 photo' : 'Uploading ${items.length} photos',
              style: SellTokens.label.copyWith(color: SellTokens.ink, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('${SellMediaCubit.bytesLabel(sent.round())} of ${SellMediaCubit.bytesLabel(total)} · resized to 1600 px to save data',
              style: SellTokens.caption),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 4,
              backgroundColor: SellTokens.track,
              color: SellTokens.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _DraggableTile extends StatelessWidget {
  const _DraggableTile({super.key, required this.item, required this.index, required this.size, required this.onTap, required this.onMove, this.label});
  final SellMediaItem item;
  final int index;
  final double size;
  final String? label;
  final VoidCallback onTap;
  final void Function(int from, int to) onMove;

  @override
  Widget build(BuildContext context) {
    final tile = _PhotoTile(item: item, size: size, label: label, onTap: onTap);
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data != index,
      onAcceptWithDetails: (d) => onMove(d.data, index),
      builder: (context, candidate, _) => AnimatedContainer(
        duration: SellTokens.fast,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SellTokens.rTile + 2),
          border: Border.all(color: candidate.isNotEmpty ? SellTokens.accent : Colors.transparent, width: 2),
        ),
        child: LongPressDraggable<int>(
          data: index,
          feedback: Material(
            color: Colors.transparent,
            elevation: 8,
            borderRadius: BorderRadius.circular(SellTokens.rTile),
            child: Transform.scale(scale: 1.04, child: _PhotoTile(item: item, size: size, label: null, onTap: () {})),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: tile),
          child: tile,
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.item, required this.size, required this.onTap, this.label});
  final SellMediaItem item;
  final double size;
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = switch (item.status) {
      SellMediaStatus.done => 'uploaded',
      SellMediaStatus.failed => 'upload failed, tap to retry',
      SellMediaStatus.paused => 'waiting for connection',
      _ => 'uploading ${(item.progress * 100).round()} percent',
    };
    return Semantics(
      button: true,
      label: '${label ?? 'Photo'}, $status',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: size - 4,
          height: size - 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(SellTokens.rTile),
            child: Stack(
              fit: StackFit.expand,
              children: [
                SellPhoto(localPath: item.localPath, url: item.url),
                if (item.status == SellMediaStatus.uploading || item.status == SellMediaStatus.queued)
                  Container(
                    color: const Color(0x730F1115),
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 34,
                      height: 34,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: item.progress),
                            duration: const Duration(milliseconds: 200),
                            builder: (_, v, __) => CircularProgressIndicator(
                              value: item.status == SellMediaStatus.queued ? null : v,
                              strokeWidth: 3,
                              color: Colors.white,
                              backgroundColor: Colors.white24,
                            ),
                          ),
                          Text('${(item.progress * 100).round()}%',
                              style: SellTokens.caption.copyWith(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                if (item.status == SellMediaStatus.paused)
                  Container(
                    color: const Color(0x730F1115),
                    alignment: Alignment.center,
                    child: const Icon(Icons.schedule_rounded, color: Colors.white),
                  ),
                if (item.isFailed)
                  Container(
                    color: const Color(0xB8C62828),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh_rounded, color: Colors.white),
                        Text('Retry', style: SellTokens.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                if (item.isDone)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.6, end: 1),
                      duration: const Duration(milliseconds: 180),
                      builder: (_, s, child) => Transform.scale(scale: s, child: child),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(color: Color(0xFF12805A), shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                if (label != null)
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xA60A0A0A), borderRadius: BorderRadius.circular(6)),
                      child: Text(label!, style: SellTokens.caption.copyWith(color: Colors.white, fontSize: 10)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.size, required this.label, required this.onTap});
  final double size;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add $label photo',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SellTokens.rTile),
        child: Container(
          width: size - 4,
          height: size - 4,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: SellTokens.surface,
            borderRadius: BorderRadius.circular(SellTokens.rTile),
            border: Border.all(color: SellTokens.line),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_a_photo_outlined, size: 20, color: SellTokens.muted),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center, style: SellTokens.caption),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.size, required this.onTap});
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add photos',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SellTokens.rTile),
        child: Container(
          width: size - 4,
          height: size - 4,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: SellTokens.surface,
            borderRadius: BorderRadius.circular(SellTokens.rTile),
            border: Border.all(color: SellTokens.accent.withValues(alpha: 0.45), width: 1.5),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: SellTokens.accent),
              Text('Add', style: SellTokens.caption.copyWith(color: SellTokens.accentText, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoRow extends StatelessWidget {
  const _VideoRow({required this.item});
  final SellMediaItem item;

  @override
  Widget build(BuildContext context) {
    final media = context.read<SellMediaCubit>();
    final subtitle = item.isFailed
        ? 'Upload failed · tap retry'
        : item.isInFlight
            ? 'Uploading ${(item.progress * 100).round()}%'
            : item.status == SellMediaStatus.paused
                ? 'Waiting for connection'
                : '${SellMediaCubit.bytesLabel(item.bytes)} · uploaded';
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: SellTokens.surface,
        borderRadius: BorderRadius.circular(SellTokens.rCard),
        border: Border.all(color: SellTokens.line),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: SellTokens.soft, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.videocam_outlined, color: SellTokens.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Video', style: SellTokens.label.copyWith(color: SellTokens.ink, fontWeight: FontWeight.w600)),
                Text(subtitle, style: SellTokens.caption.copyWith(color: item.isFailed ? SellTokens.errorText : SellTokens.muted)),
              ],
            ),
          ),
          if (item.isFailed)
            IconButton(tooltip: 'Retry video', onPressed: () => media.retry(item.localId), icon: Icon(Icons.refresh_rounded, color: SellTokens.accent)),
          IconButton(tooltip: 'Remove video', onPressed: () => media.remove(item.localId), icon: Icon(Icons.close_rounded, color: SellTokens.muted)),
        ],
      ),
    );
  }
}
