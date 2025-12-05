import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/features/home/ui/edit_add_details/widgets/section_title_widget.dart';
import 'package:ado_dad_user/features/home/ui/edit_add_details/widgets/video_picker_widget.dart';
import 'package:flutter/material.dart';

class VideoUploadSectionWidget extends StatelessWidget {
  final String? videoFileName;
  final String? existingVideoUrl;
  final VoidCallback onPickVideo;
  final VoidCallback? onRemoveVideo;

  const VideoUploadSectionWidget({
    super.key,
    this.videoFileName,
    this.existingVideoUrl,
    required this.onPickVideo,
    this.onRemoveVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(
          GetResponsiveSize.getResponsiveBorderRadius(
            context,
            mobile: 12,
            tablet: 16,
            largeTablet: 20,
            desktop: 24,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: GetResponsiveSize.getResponsivePadding(
            context,
            mobile: 16,
            tablet: 24,
            largeTablet: 32,
            desktop: 40,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 10,
                tablet: 14,
                largeTablet: 18,
                desktop: 22,
              ),
            ),
            const SectionTitleWidget(title: 'Upload Video'),
            SizedBox(
              height: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 20,
                tablet: 28,
                largeTablet: 36,
                desktop: 44,
              ),
            ),
            VideoPickerWidget(
              videoFileName: videoFileName,
              existingVideoUrl: existingVideoUrl,
              onPickVideo: onPickVideo,
              onRemoveVideo: onRemoveVideo,
            ),
            SizedBox(
              height: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 20,
                tablet: 28,
                largeTablet: 36,
                desktop: 44,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
