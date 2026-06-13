import 'package:ado_dad_user/common/app_colors.dart';
import 'package:flutter/material.dart';

/// Loads remote images with a placeholder, broken-image fallback, and one retry
/// for transient network failures (common with S3 on slow connections).
class AppNetworkImage extends StatefulWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.retryCount = 1,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final int retryCount;

  @override
  State<AppNetworkImage> createState() => _AppNetworkImageState();
}

class _AppNetworkImageState extends State<AppNetworkImage> {
  int _attempt = 0;

  bool get _hasUrl => widget.url.trim().isNotEmpty;

  void _scheduleRetry() {
    if (!mounted || _attempt >= widget.retryCount) return;
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _attempt++);
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

  @override
  Widget build(BuildContext context) {
    if (!_hasUrl) {
      return _placeholder(broken: true);
    }

    final image = Image.network(
      widget.url,
      key: ValueKey('${widget.url}#$_attempt'),
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _placeholder(loading: true);
      },
      errorBuilder: (context, error, stackTrace) {
        if (_attempt < widget.retryCount) {
          _scheduleRetry();
          return _placeholder(loading: true);
        }
        return _placeholder(broken: true);
      },
    );

    if (widget.borderRadius == null) return image;

    return ClipRRect(
      borderRadius: widget.borderRadius!,
      child: image,
    );
  }
}
