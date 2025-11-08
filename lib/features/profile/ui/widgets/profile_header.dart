import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 16,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            icon: Icon(
              (!kIsWeb && Platform.isIOS)
                  ? Icons.arrow_back_ios
                  : Icons.arrow_back,
              color: Colors.white,
            ),
            iconSize: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 28,
              tablet: 36,
              largeTablet: 40,
              desktop: 42,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "Profile",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: GetResponsiveSize.getResponsiveFontSize(
                context,
                mobile: 20,
                tablet: 26,
                largeTablet: 30,
                desktop: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
