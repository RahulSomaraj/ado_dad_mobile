import 'dart:typed_data';

import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:flutter/material.dart';

class ImagePickerWidget extends StatelessWidget {
  final List<String> imageUrls;
  final List<Uint8List> newImageFiles;
  final VoidCallback onPickImages;
  final ValueChanged<String> onRemoveImage;
  final ValueChanged<int>? onRemoveNewImage;

  const ImagePickerWidget({
    super.key,
    required this.imageUrls,
    required this.newImageFiles,
    required this.onPickImages,
    required this.onRemoveImage,
    this.onRemoveNewImage,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: GetResponsiveSize.getResponsiveSize(
        context,
        mobile: 10,
        tablet: 14,
        largeTablet: 18,
        desktop: 22,
      ),
      runSpacing: GetResponsiveSize.getResponsiveSize(
        context,
        mobile: 10,
        tablet: 14,
        largeTablet: 18,
        desktop: 22,
      ),
      children: [
        ...imageUrls.asMap().entries.map((urlEntry) {
          final url = urlEntry.value;
          final isCover = urlEntry.key == 0;
          return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                  url,
                  width: GetResponsiveSize.getResponsiveSize(
                    context,
                    mobile: 100,
                    tablet: 130,
                    largeTablet: 160,
                    desktop: 190,
                  ),
                  height: GetResponsiveSize.getResponsiveSize(
                    context,
                    mobile: 100,
                    tablet: 130,
                    largeTablet: 160,
                    desktop: 190,
                  ),
                  fit: BoxFit.cover,
                ),
                ),
                if (isCover)
                  Positioned(
                    left: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'COVER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: () => onRemoveImage(url),
                    child: Container(
                      color: Colors.black54,
                      padding: EdgeInsets.all(
                        GetResponsiveSize.getResponsivePadding(
                          context,
                          mobile: 2,
                          tablet: 4,
                          largeTablet: 6,
                          desktop: 8,
                        ),
                      ),
                      child: Icon(
                        Icons.close,
                        size: GetResponsiveSize.getResponsiveSize(
                          context,
                          mobile: 14,
                          tablet: 18,
                          largeTablet: 22,
                          desktop: 26,
                        ),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
        }),
        ...newImageFiles.asMap().entries.map((entry) {
          final index = entry.key;
          final bytes = entry.value;
          return Stack(
            children: [
              Image.memory(
                bytes,
                width: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 100,
                  tablet: 130,
                  largeTablet: 160,
                  desktop: 190,
                ),
                height: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 100,
                  tablet: 130,
                  largeTablet: 160,
                  desktop: 190,
                ),
                fit: BoxFit.cover,
              ),
              if (onRemoveNewImage != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => onRemoveNewImage!(index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.rectangle,
                      ),
                      padding: EdgeInsets.all(
                        GetResponsiveSize.getResponsivePadding(
                          context,
                          mobile: 2,
                          tablet: 4,
                          largeTablet: 6,
                          desktop: 8,
                        ),
                      ),
                      child: Icon(
                        Icons.close,
                        size: GetResponsiveSize.getResponsiveSize(
                          context,
                          mobile: 14,
                          tablet: 18,
                          largeTablet: 22,
                          desktop: 26,
                        ),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
        GestureDetector(
          onTap: onPickImages,
          child: Container(
            width: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 100,
              tablet: 130,
              largeTablet: 160,
              desktop: 190,
            ),
            height: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 100,
              tablet: 130,
              largeTablet: 160,
              desktop: 190,
            ),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(
                color: AppColors.greyColor.withOpacity(0.6),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.add,
              color: AppColors.primaryColor,
              size: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 24,
                tablet: 32,
                largeTablet: 40,
                desktop: 48,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
