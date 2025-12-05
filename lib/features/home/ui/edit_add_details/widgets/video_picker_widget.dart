import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:flutter/material.dart';

class VideoPickerWidget extends StatelessWidget {
  final String? videoFileName;
  final String? existingVideoUrl;
  final VoidCallback onPickVideo;
  final VoidCallback? onRemoveVideo;

  const VideoPickerWidget({
    super.key,
    this.videoFileName,
    this.existingVideoUrl,
    required this.onPickVideo,
    this.onRemoveVideo,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = videoFileName ??
        (existingVideoUrl != null ? existingVideoUrl! : 'No video selected');
    final hasVideo = videoFileName != null || existingVideoUrl != null;
    // In edit forms: if existingVideoUrl is present, only show close button, hide Choose File
    // Once removed (existingVideoUrl is null), show Choose File button
    final showChooseFileButton = existingVideoUrl == null;

    return Container(
      height: GetResponsiveSize.getResponsiveSize(
        context,
        mobile: 56,
        tablet: 70,
        largeTablet: 84,
        desktop: 98,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(
          GetResponsiveSize.getResponsiveBorderRadius(
            context,
            mobile: 8,
            tablet: 10,
            largeTablet: 12,
            desktop: 14,
          ),
        ),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: GetResponsiveSize.getResponsivePadding(
                  context,
                  mobile: 16,
                  tablet: 20,
                  largeTablet: 24,
                  desktop: 28,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayText,
                      style: TextStyle(
                        color: hasVideo ? Colors.black87 : Colors.grey.shade500,
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 20,
                          largeTablet: 24,
                          desktop: 28,
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasVideo && onRemoveVideo != null)
                    GestureDetector(
                      onTap: onRemoveVideo,
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Only show Choose File button if there's no existing video (after removal)
          if (showChooseFileButton)
            Container(
              height: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 56,
                tablet: 70,
                largeTablet: 84,
                desktop: 98,
              ),
              width: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 120,
                tablet: 150,
                largeTablet: 180,
                desktop: 210,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(
                    GetResponsiveSize.getResponsiveBorderRadius(
                      context,
                      mobile: 8,
                      tablet: 10,
                      largeTablet: 12,
                      desktop: 14,
                    ),
                  ),
                  bottomRight: Radius.circular(
                    GetResponsiveSize.getResponsiveBorderRadius(
                      context,
                      mobile: 8,
                      tablet: 10,
                      largeTablet: 12,
                      desktop: 14,
                    ),
                  ),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPickVideo,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(
                      GetResponsiveSize.getResponsiveBorderRadius(
                        context,
                        mobile: 8,
                        tablet: 10,
                        largeTablet: 12,
                        desktop: 14,
                      ),
                    ),
                    bottomRight: Radius.circular(
                      GetResponsiveSize.getResponsiveBorderRadius(
                        context,
                        mobile: 8,
                        tablet: 10,
                        largeTablet: 12,
                        desktop: 14,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.upload_file,
                          color: Colors.black,
                          size: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 18,
                            tablet: 24,
                            largeTablet: 30,
                            desktop: 36,
                          ),
                        ),
                        SizedBox(
                          width: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 4,
                            tablet: 6,
                            largeTablet: 8,
                            desktop: 10,
                          ),
                        ),
                        Text(
                          'Choose File',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: GetResponsiveSize.getResponsiveFontSize(
                              context,
                              mobile: 14,
                              tablet: 18,
                              largeTablet: 22,
                              desktop: 26,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
