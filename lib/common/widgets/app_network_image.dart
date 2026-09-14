import 'dart:async';

import 'package:ado_dad_user/common/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Loads remote images with a placeholder, broken-image fallback, and one retry
/// for transient network failures (common with S3 on slow connections).
///
/// Two things this does that plain `Image.network` did not:
///
/// * **Disk cache.** `Image.network` only ever used Flutter's in-memory
///   `ImageCache`, which is 100 MB. At S3 original size (a 3000x2000 phone
///   photo decodes to ~24 MB of ARGB) that holds barely four images, so a
///   20-card grid evicted continuously and every eviction meant re-downloading
///   from S3. `CachedNetworkImage` persists the encoded bytes to disk, so a
///   scroll back up — or reopening an ad — costs nothing.
///
/// * **Right-sized decode.** The image is decoded at the size it will actually
///   be painted at (`memCacheWidth`), not at whatever the seller's camera
///   produced. A 172pt-wide ad card needs ~517 device pixels; decoding the
///   original was roughly 36x more memory than the card could use.
///
/// Because the disk cache is keyed by URL and independent of decode size, the
/// full-resolution fullscreen viewer still reads the bytes this widget already
/// downloaded instead of fetching them again.
class AppNetworkImage extends StatefulWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.retryCount = 1,
    this.fullResolution = false,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final int retryCount;

  /// Set for zoomable / fullscreen surfaces that genuinely need every pixel.
  /// Everywhere else the image is decoded to fit its slot.
  final bool fullResolution;

  @override
  State<AppNetworkImage> createState() => _AppNetworkImageState();
}

class _AppNetworkImageState extends State<AppNetworkImage> {
  int _attempt = 0;

  /// Guards against the duplicate-timer bug: `errorWidget` is called during
  /// build and runs again on every rebuild while the widget is in its error
  /// state. Incrementing `_attempt` only after the delay elapsed meant any
  /// rebuild inside that 500 ms window scheduled a second timer, and both
  /// fired.
  bool _retryPending = false;

  bool get _hasUrl => widget.url.trim().isNotEmpty;

  void _scheduleRetry() {
    if (!mounted || _retryPending || _attempt >= widget.retryCount) return;
    _retryPending = true;
    Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) {
        _retryPending = false;
        return;
      }
      // Drop the failed entry so the next build actually refetches rather than
      // replaying the cached failure.
      await CachedNetworkImage.evictFromCache(widget.url);
      if (!mounted) {
        _retryPending = false;
        return;
      }
      setState(() {
        _attempt++;
        _retryPending = false;
      });
    });
  }

  Widget _placeholder({bool loading = false, bool broken = false}) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: AppColors.scaffoldBackground,
      alignment: Alignment.center,
      child: loading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryColor.withOpacity(0.7),
              ),
            )
          : Icon(
              broken ? Icons.broken_image_outlined : Icons.image_outlined,
              color: AppColors.greyColor,
            ),
    );
  }

  /// Target decode width in device pixels, or null when the slot has no bounded
  /// width to measure against (then we let the decoder use the source size).
  int? _decodeWidth(BuildContext context, BoxConstraints constraints) {
    if (widget.fullResolution) return null;
    final double? logical = widget.width ??
        (constraints.hasBoundedWidth ? constraints.maxWidth : null);
    if (logical == null || !logical.isFinite || logical <= 0) return null;
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    return (logical * dpr).round();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasUrl) {
      return _placeholder(broken: true);
    }

    final image = LayoutBuilder(
      builder: (context, constraints) {
        return CachedNetworkImage(
          imageUrl: widget.url,
          // Bumping the attempt changes the widget identity on retry so the
          // evicted URL is resolved again from scratch.
          key: ValueKey('${widget.url}#$_attempt'),
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          memCacheWidth: _decodeWidth(context, constraints),
          // Once the image is decoded at its painted size there is no
          // minification left for a mipmap to help with.
          filterQuality: FilterQuality.low,
          fadeInDuration: const Duration(milliseconds: 120),
          fadeOutDuration: const Duration(milliseconds: 60),
          // One placeholder state, not shimmer-then-spinner. progressIndicator
          // is used so the spinner reflects real bytes received instead of
          // throwing that information away.
          progressIndicatorBuilder: (context, url, progress) {
            return Container(
              width: widget.width,
              height: widget.height,
              color: AppColors.scaffoldBackground,
              alignment: Alignment.center,
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: progress.progress,
                  color: AppColors.primaryColor.withOpacity(0.7),
                ),
              ),
            );
          },
          errorWidget: (context, url, error) {
            if (_attempt < widget.retryCount) {
              _scheduleRetry();
              return _placeholder(loading: true);
            }
            return _placeholder(broken: true);
          },
        );
      },
    );

    if (widget.borderRadius == null) return image;

    return ClipRRect(
      borderRadius: widget.borderRadius!,
      child: image,
    );
  }
}
