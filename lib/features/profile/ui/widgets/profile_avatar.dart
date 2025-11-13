import 'dart:typed_data';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final Uint8List? pickedImageBytes;
  final String? currentProfilePicUrl;
  final bool isEditing;
  final VoidCallback onPickImage;

  const ProfileAvatar({
    super.key,
    this.pickedImageBytes,
    this.currentProfilePicUrl,
    required this.isEditing,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: GetResponsiveSize.getResponsiveSize(
        context,
        mobile: 75,
        tablet: 70,
        largeTablet: 80,
        desktop: 85,
      ),
      left: MediaQuery.of(context).size.width / 2 -
          GetResponsiveSize.getResponsiveSize(
            context,
            mobile: 50,
            tablet: 65,
            largeTablet: 80,
            desktop: 90,
          ),
      child: Stack(
        children: [
          CircleAvatar(
            radius: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 50,
              tablet: 80,
              largeTablet: 100,
              desktop: 110,
            ),
            backgroundColor: AppColors.greyColor,
            backgroundImage: pickedImageBytes != null
                ? MemoryImage(pickedImageBytes!)
                : (currentProfilePicUrl != null &&
                        currentProfilePicUrl!.isNotEmpty &&
                        currentProfilePicUrl != 'default-profile-pic-url' &&
                        currentProfilePicUrl!.startsWith('http'))
                    ? NetworkImage(currentProfilePicUrl!) as ImageProvider
                    : null,
            child: (pickedImageBytes == null &&
                    (currentProfilePicUrl == null ||
                        currentProfilePicUrl!.isEmpty ||
                        currentProfilePicUrl == 'default-profile-pic-url' ||
                        !currentProfilePicUrl!.startsWith('http')))
                ? Icon(Icons.person,
                    size: GetResponsiveSize.getResponsiveSize(
                      context,
                      mobile: 50,
                      tablet: 80,
                      largeTablet: 96,
                      desktop: 110,
                    ),
                    color: Colors.white)
                : null,
          ),
          if (isEditing)
            Positioned(
              right: 0,
              bottom: 0,
              child: InkWell(
                onTap: onPickImage,
                child: Container(
                  padding: EdgeInsets.all(
                    GetResponsiveSize.getResponsiveSize(
                      context,
                      mobile: 6,
                      tablet: 8,
                      largeTablet: 10,
                      desktop: 10,
                    ),
                  ),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Icon(
                    Icons.edit,
                    size: GetResponsiveSize.getResponsiveSize(
                      context,
                      mobile: 18,
                      tablet: 26,
                      largeTablet: 30,
                      desktop: 32,
                    ),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}
