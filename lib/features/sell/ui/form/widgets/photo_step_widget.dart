import 'dart:typed_data';

import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/features/sell/bloc/media_upload/media_upload_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

/// Step 1 of the post-ad flow: photos first.
///
/// Shared by every category form. Reads/writes [MediaUploadBloc], which must be
/// provided above this widget. Uploads start as soon as a file is picked so the
/// seller can keep filling the form while S3 does its work.
class PhotoStepWidget extends StatefulWidget {
  final String categoryId;
  const PhotoStepWidget({super.key, required this.categoryId});

  @override
  State<PhotoStepWidget> createState() => _PhotoStepWidgetState();
}

class _PhotoStepWidgetState extends State<PhotoStepWidget> {
  final ImagePicker _picker = ImagePicker();

  String get _subject {
    switch (widget.categoryId) {
      case 'two_wheeler':
        return 'your bike';
      case 'private_vehicle':
        return 'your car';
      case 'commercial_vehicle':
        return 'your vehicle';
      case 'property':
        return 'the property';
      default:
        return 'your item';
    }
  }

  List<String> get _tips {
    switch (widget.categoryId) {
      case 'property':
        return [
          'Front of the building in daylight',
          'Living room, kitchen and bedrooms',
          'Balcony / view and parking',
        ];
      case 'commercial_vehicle':
        return [
          'Front three-quarter view in daylight',
          'Cargo area / cabin and odometer',
          'Tyres, RC and any damage',
        ];
      case 'two_wheeler':
        return [
          'Side profile in daylight',
          'Odometer and engine',
          'Tyres and any scratches',
        ];
      default:
        return [
          'Front three-quarter view in daylight',
          'Odometer and dashboard',
          'Interior, tyres and any damage',
        ];
    }
  }

  MediaUploadBloc get _bloc => context.read<MediaUploadBloc>();

  Future<void> _pickFromCamera() async {
    final picked =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    _bloc.add(MediaUploadEvent.imagesAdded([bytes]));
  }

  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickMultiImage(imageQuality: 70);
    if (picked.isEmpty) return;
    final List<Uint8List> files = [];
    for (final p in picked) {
      files.add(await p.readAsBytes());
    }
    _bloc.add(MediaUploadEvent.imagesAdded(files));
  }

  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    _bloc.add(MediaUploadEvent.videoAdded(file: bytes, fileName: picked.name));
  }

  void _showAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTileSheet(MediaItem item, int index) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index != 0)
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('Set as cover photo'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _bloc.add(MediaUploadEvent.coverSet(item.localId));
                },
              ),
            if (index > 0)
              ListTile(
                leading: const Icon(Icons.arrow_upward),
                title: const Text('Move earlier'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _bloc.add(MediaUploadEvent.imageMoved(
                      oldIndex: index, newIndex: index - 1));
                },
              ),
            if (item.isFailed)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Retry upload'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _bloc.add(MediaUploadEvent.retryRequested(item.localId));
                },
              ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.redColor),
              title: Text('Remove', style: TextStyle(color: AppColors.redColor)),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _bloc.add(MediaUploadEvent.imageRemoved(item.localId));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = GetResponsiveSize.getResponsivePadding(
      context,
      mobile: 16,
      tablet: 24,
      largeTablet: 32,
      desktop: 40,
    );
    return BlocBuilder<MediaUploadBloc, MediaUploadState>(
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                'Add photos of $_subject',
                style: AppTextstyle.sectionTitleTextStyle.copyWith(
                  fontSize: GetResponsiveSize.getResponsiveFontSize(
                    context,
                    mobile: AppTextstyle.sectionTitleTextStyle.fontSize ?? 18,
                    tablet: 24,
                    largeTablet: 30,
                    desktop: 36,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ads with 5 or more photos get far more enquiries. '
                'The first photo is the cover.',
                style: TextStyle(
                  color: AppColors.greyColor,
                  fontSize: GetResponsiveSize.getResponsiveFontSize(
                    context,
                    mobile: 13,
                    tablet: 16,
                    largeTablet: 19,
                    desktop: 22,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!state.hasImages) _buildEmptyDrop(context) else ...[
                _buildCountRow(context, state),
                const SizedBox(height: 10),
                _buildGrid(context, state),
              ],
              if (!state.hasImages) ...[
                const SizedBox(height: 16),
                _buildTips(context),
              ],
              const SizedBox(height: 20),
              _buildVideoCard(context, state),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyDrop(BuildContext context) {
    return InkWell(
      onTap: _showAddSheet,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryColor, width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.photo_camera_outlined,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              'Take photo',
              style: AppTextstyle.buttonText.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'or choose from gallery · up to '
              '${context.read<MediaUploadBloc>().state.maxImages}',
              style: TextStyle(color: AppColors.greyColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTips(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.greyColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GOOD SHOTS TO INCLUDE',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: AppColors.greyColor,
            ),
          ),
          const SizedBox(height: 8),
          for (final tip in _tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(tip,
                        style: TextStyle(
                            fontSize: 13, color: AppColors.blackColor1)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCountRow(BuildContext context, MediaUploadState state) {
    final String status;
    if (state.hasFailed) {
      status = 'Some uploads failed · tap to retry';
    } else if (state.isUploading) {
      status = 'Uploading ${state.uploadedCount}/${state.images.length}…';
    } else {
      status = 'Tap a photo for options';
    }
    return Row(
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(color: AppColors.greyColor, fontSize: 12),
            children: [
              TextSpan(
                text: '${state.images.length}',
                style: TextStyle(
                    color: AppColors.blackColor, fontWeight: FontWeight.w700),
              ),
              TextSpan(text: ' of ${state.maxImages} photos'),
            ],
          ),
        ),
        const Spacer(),
        Text(
          status,
          style: TextStyle(
            color: state.hasFailed ? AppColors.redColor : AppColors.greyColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, MediaUploadState state) {
    final items = state.images;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: items.length + (state.canAddMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return InkWell(
            onTap: _showAddSheet,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryColor),
              ),
              child: Icon(Icons.add, color: AppColors.primaryColor, size: 28),
            ),
          );
        }
        final item = items[index];
        return _PhotoTile(
          item: item,
          isCover: index == 0,
          onTap: () => _showTileSheet(item, index),
        );
      },
    );
  }

  Widget _buildVideoCard(BuildContext context, MediaUploadState state) {
    final video = state.video;
    final String subtitle;
    if (video == null) {
      subtitle = 'Optional · a short walk-around helps buyers';
    } else if (video.isFailed) {
      subtitle = 'Upload failed · tap retry';
    } else if (video.isInFlight) {
      subtitle = 'Uploading ${video.fileName ?? 'video'}…';
    } else {
      subtitle = video.fileName ?? 'Video added';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.greyColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.greyColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: video != null && video.isInFlight
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    video == null
                        ? Icons.videocam_outlined
                        : video.isFailed
                            ? Icons.error_outline
                            : Icons.check_circle,
                    color: video == null
                        ? AppColors.blackColor1
                        : video.isFailed
                            ? AppColors.redColor
                            : Colors.green,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video == null ? 'Add a video' : 'Video',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.blackColor,
                      fontSize: 13),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.greyColor, fontSize: 11.5),
                ),
              ],
            ),
          ),
          if (video == null)
            TextButton(onPressed: _pickVideo, child: const Text('Add'))
          else ...[
            if (video.isFailed)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () =>
                    _bloc.add(MediaUploadEvent.retryRequested(video.localId)),
              ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _bloc.add(const MediaUploadEvent.videoRemoved()),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final MediaItem item;
  final bool isCover;
  final VoidCallback onTap;
  const _PhotoTile(
      {required this.item, required this.isCover, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Widget image = item.bytes != null
        ? Image.memory(item.bytes!, fit: BoxFit.cover)
        : (item.url != null
            ? Image.network(item.url!, fit: BoxFit.cover)
            : const SizedBox.shrink());

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            if (item.isInFlight)
              Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                ),
              ),
            if (item.isFailed)
              Container(
                color: Colors.black.withValues(alpha: 0.45),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, color: Colors.white),
                      Text('Retry',
                          style: TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            if (isCover)
              Positioned(
                left: 6,
                top: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'COVER',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8),
                  ),
                ),
              ),
            if (item.isDone)
              const Positioned(
                right: 6,
                bottom: 6,
                child: Icon(Icons.check_circle, color: Colors.green, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}
