// Media viewers for the ad detail page, moved out of add_detail_page.dart
// unchanged apart from the class names (were private `_VideoPlayerWidget`,
// `_ImageGalleryViewer`, `_VideoFullScreenViewer`).
import 'dart:io' show Platform;

import 'package:ado_dad_user/common/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:video_player/video_player.dart';

class AdDetailVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onVideoComplete;

  const AdDetailVideoPlayer({
    super.key,
    required this.videoUrl,
    this.onVideoComplete,
  });

  @override
  State<AdDetailVideoPlayer> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<AdDetailVideoPlayer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isLoading = true;
  bool _hasCalledCompletion = false; // Prevent multiple callback calls

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {

      // Validate URL
      if (widget.videoUrl.isEmpty) {
        throw Exception('Video URL is empty');
      }

      // Clean and validate URL
      String cleanUrl = widget.videoUrl.trim();
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }

      final uri = Uri.parse(cleanUrl);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        throw Exception('Invalid video URL format: $cleanUrl');
      }

      // Skip URL accessibility test as it often fails unnecessarily
      // and video player can handle network issues better

      _videoPlayerController = VideoPlayerController.networkUrl(uri);

      // Add listener to update UI when video state changes
      _videoPlayerController!.addListener(_videoListener);

      // Add timeout to video initialization
      await _videoPlayerController!.initialize().timeout(
        const Duration(seconds: 15), // Reduced timeout
        onTimeout: () {
          throw Exception('Video initialization timeout after 15 seconds');
        },
      );

      // Initialize Chewie controller with proper controls
      // Disable auto-play in carousel - user will tap to open full screen
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false, // Disable autoplay - user taps to open full screen
        looping: false,
        allowPlaybackSpeedChanging: false, // Disable in carousel
        allowMuting: false, // Disable sound controls
        showControls:
            false, // Hide controls in carousel - show play button overlay instead
        showOptions: false, // Disable options in carousel
        allowFullScreen: false, // Disable fullscreen
        startAt: Duration.zero, // Start from beginning
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryColor,
          handleColor: Colors.white,
          backgroundColor: Colors.grey.withValues(alpha: 0.3),
          bufferedColor: Colors.lightBlueAccent.withValues(alpha: 0.3),
        ),
        cupertinoProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryColor,
          handleColor: Colors.white,
          backgroundColor: Colors.grey.withValues(alpha: 0.3),
          bufferedColor: Colors.lightBlueAccent.withValues(alpha: 0.3),
        ),
        // Keep controls hidden in carousel
        hideControlsTimer: const Duration(seconds: 0),
        showControlsOnInitialize: false,
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = _getUserFriendlyErrorMessage(e);
        });
      }
    }
  }

  void _videoListener() {
    if (mounted && _videoPlayerController != null) {
      final value = _videoPlayerController!.value;

      if (value.hasError && value.errorDescription != null) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage =
              _getUserFriendlyErrorMessage(Exception(value.errorDescription!));
        });
      } else if (value.isInitialized && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }

      // Reset completion flag if video position resets (user seeks back, etc.)
      if (value.position < value.duration - const Duration(seconds: 1)) {
        _hasCalledCompletion = false;
      }

      // Check if video has completed
      if (value.isInitialized &&
          value.duration > Duration.zero &&
          value.position >=
              value.duration - const Duration(milliseconds: 100) &&
          !_hasCalledCompletion) {
        // Video has reached the end (with 100ms tolerance)
        _hasCalledCompletion = true;
        widget.onVideoComplete?.call();
      }
    }
  }

  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout')) {
      return 'Video loading timeout. Please check your internet connection.';
    } else if (errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorString.contains('format') ||
        errorString.contains('codec')) {
      return 'Video format not supported.';
    } else if (errorString.contains('not found') ||
        errorString.contains('404')) {
      return 'Video not found.';
    } else if (errorString.contains('permission') ||
        errorString.contains('access')) {
      return 'Access denied to video.';
    } else {
      return 'Unable to load video. Please try again.';
    }
  }

  Future<void> _testWithSampleVideo() async {
    try {

      // Use a known working sample video URL
      const testVideoUrl =
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

      _videoPlayerController?.removeListener(_videoListener);
      _videoPlayerController?.dispose();
      _chewieController?.dispose();

      _videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(testVideoUrl));

      // Add listener to update UI when video state changes
      _videoPlayerController!.addListener(_videoListener);

      await _videoPlayerController!.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Test video initialization timeout after 15 seconds');
        },
      );

      // Initialize Chewie controller for test video
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        allowPlaybackSpeedChanging: true,
        allowMuting: false, // Disable sound controls
        showControls: true,
        showOptions: true,
        allowFullScreen: false, // Disable fullscreen
        startAt: Duration.zero,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryColor,
          handleColor: Colors.white,
          backgroundColor: Colors.grey.withValues(alpha: 0.3),
          bufferedColor: Colors.lightBlueAccent.withValues(alpha: 0.3),
        ),
        cupertinoProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryColor,
          handleColor: Colors.white,
          backgroundColor: Colors.grey.withValues(alpha: 0.3),
          bufferedColor: Colors.lightBlueAccent.withValues(alpha: 0.3),
        ),
        hideControlsTimer: const Duration(seconds: 3),
        showControlsOnInitialize: true,
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage =
              'Test video failed: ${_getUserFriendlyErrorMessage(e)}';
        });
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.removeListener(_videoListener);
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.videocam_off,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Video not available',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _isInitialized = false;
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        _initializeVideo();
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _isInitialized = false;
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        _testWithSampleVideo();
                      },
                      icon: const Icon(Icons.play_circle_outline, size: 18),
                      label: const Text('Test Video'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoading || !_isInitialized || _chewieController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
              SizedBox(height: 12),
              Text(
                'Loading video...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Return Chewie - parent will use AbsorbPointer to prevent tap interception
    return Chewie(controller: _chewieController!);
  }
}

/// Full-screen image gallery viewer with zoom and pan capabilities
/// Neutral near-black: pure #000 makes photos look harsher and crushes shadows.
const Color _kGalleryGround = Color(0xFF1B1E24);

class AdDetailImageGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const AdDetailImageGallery({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<AdDetailImageGallery> createState() => _ImageGalleryViewerState();
}

class _ImageGalleryViewerState extends State<AdDetailImageGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kGalleryGround,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            (!kIsWeb && Platform.isIOS)
                ? Icons.arrow_back_ios
                : Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            // Cached provider, so opening fullscreen reuses the bytes the
            // carousel already downloaded instead of re-fetching from S3.
            // Full-resolution decode here is deliberate — this view zooms.
            imageProvider: CachedNetworkImageProvider(widget.images[index]),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            heroAttributes: PhotoViewHeroAttributes(
              tag: widget.images[index],
            ),
          );
        },
        itemCount: widget.images.length,
        loadingBuilder: (context, event) => Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              // Indeterminate when the server sends no Content-Length.
              value: (event == null || event.expectedTotalBytes == null)
                  ? null
                  : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        pageController: _pageController,
        onPageChanged: _onPageChanged,
        backgroundDecoration: const BoxDecoration(
          color: _kGalleryGround,
        ),
      ),
    );
  }
}

/// Full-screen video player viewer
class AdDetailVideoFullScreen extends StatefulWidget {
  final String videoUrl;

  const AdDetailVideoFullScreen({
    super.key,
    required this.videoUrl,
  });

  @override
  State<AdDetailVideoFullScreen> createState() => _VideoFullScreenViewerState();
}

class _VideoFullScreenViewerState extends State<AdDetailVideoFullScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {

      if (widget.videoUrl.isEmpty) {
        throw Exception('Video URL is empty');
      }

      String cleanUrl = widget.videoUrl.trim();
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }

      final uri = Uri.parse(cleanUrl);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        throw Exception('Invalid video URL format: $cleanUrl');
      }

      _videoPlayerController = VideoPlayerController.networkUrl(uri);
      _videoPlayerController!.addListener(_videoListener);

      await _videoPlayerController!.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Video initialization timeout after 15 seconds');
        },
      );

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        allowPlaybackSpeedChanging: true,
        allowMuting: true,
        showControls: true,
        showOptions: true,
        allowFullScreen: true,
        startAt: Duration.zero,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryColor,
          handleColor: Colors.white,
          backgroundColor: Colors.grey.withValues(alpha: 0.3),
          bufferedColor: Colors.lightBlueAccent.withValues(alpha: 0.3),
        ),
        cupertinoProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryColor,
          handleColor: Colors.white,
          backgroundColor: Colors.grey.withValues(alpha: 0.3),
          bufferedColor: Colors.lightBlueAccent.withValues(alpha: 0.3),
        ),
        hideControlsTimer: const Duration(seconds: 3),
        showControlsOnInitialize: true,
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = _getUserFriendlyErrorMessage(e);
        });
      }
    }
  }

  void _videoListener() {
    if (mounted && _videoPlayerController != null) {
      final value = _videoPlayerController!.value;
      if (value.hasError && value.errorDescription != null) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage =
              _getUserFriendlyErrorMessage(Exception(value.errorDescription!));
        });
      } else if (value.isInitialized && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('timeout')) {
      return 'Video loading timeout. Please check your internet connection.';
    } else if (errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorString.contains('format') ||
        errorString.contains('codec')) {
      return 'Video format not supported.';
    } else if (errorString.contains('not found') ||
        errorString.contains('404')) {
      return 'Video not found.';
    } else if (errorString.contains('permission') ||
        errorString.contains('access')) {
      return 'Access denied to video.';
    } else {
      return 'Unable to load video. Please try again.';
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.removeListener(_videoListener);
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            (!kIsWeb && Platform.isIOS)
                ? Icons.arrow_back_ios
                : Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _hasError
          ? Container(
              color: Colors.black,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off,
                          color: Colors.white, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Video not available',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _hasError = false;
                            _isInitialized = false;
                            _isLoading = true;
                            _errorMessage = null;
                          });
                          _initializeVideo();
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : _isLoading || !_isInitialized || _chewieController == null
              ? Container(
                  color: Colors.black,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                        SizedBox(height: 12),
                        Text(
                          'Loading video...',
                          style:
                              TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              : Center(child: Chewie(controller: _chewieController!)),
    );
  }
}
