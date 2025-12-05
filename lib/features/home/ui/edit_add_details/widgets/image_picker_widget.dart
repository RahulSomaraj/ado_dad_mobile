import 'dart:typed_data';

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
        ...imageUrls.map((url) => Stack(
              children: [
                Image.network(
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
            )),
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
            color: Colors.grey.shade300,
            child: Icon(
              Icons.add,
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
