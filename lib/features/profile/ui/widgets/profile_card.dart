import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/features/profile/ui/widgets/profile_label.dart';
import 'package:ado_dad_user/features/profile/ui/widgets/profile_text_field.dart';
import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final bool isEditing;
  final VoidCallback onEditTap;
  final VoidCallback onSaveTap;

  const ProfileCard({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.isEditing,
    required this.onEditTap,
    required this.onSaveTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: GetResponsiveSize.getResponsiveSize(
        context,
        mobile: 120,
        tablet: 150,
        largeTablet: 180,
        desktop: 200,
      ),
      left: 20,
      right: 20,
      child: Container(
        padding: EdgeInsets.all(
          GetResponsiveSize.getResponsiveSize(
            context,
            mobile: 16,
            tablet: 20,
            largeTablet: 24,
            desktop: 26,
          ),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: isEditing ? onSaveTap : onEditTap,
                child: isEditing
                    ? Container(
                        padding: EdgeInsets.all(
                          GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 8,
                            tablet: 12,
                            largeTablet: 14,
                            desktop: 14,
                          ),
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 20,
                            tablet: 28,
                            largeTablet: 32,
                            desktop: 34,
                          ),
                        ),
                      )
                    : SizedBox(
                        width: GetResponsiveSize.getResponsiveSize(
                          context,
                          mobile: 24,
                          tablet: 36,
                          largeTablet: 42,
                          desktop: 44,
                        ),
                        height: GetResponsiveSize.getResponsiveSize(
                          context,
                          mobile: 24,
                          tablet: 36,
                          largeTablet: 42,
                          desktop: 44,
                        ),
                        child: Image.asset(
                          'assets/images/profile-edit-icon.png',
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
            ),
            const ProfileLabel(text: "Full Name"),
            ProfileTextField(
              controller: nameController,
              isEditable: isEditing,
            ),
            const ProfileLabel(text: "Email"),
            ProfileTextField(
              controller: emailController,
              isEditable: isEditing,
            ),
            const ProfileLabel(text: "Phone Number"),
            ProfileTextField(
              controller: phoneController,
              isEditable: isEditing,
              isPhoneField: true,
            ),
          ],
        ),
      ),
    );
  }
}
