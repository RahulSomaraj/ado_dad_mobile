import 'package:ado_dad_user/features/home/ui/home_page.dart';
import 'package:flutter/material.dart';

class IosHomeMobile extends StatelessWidget {
  const IosHomeMobile({super.key, this.showLoginPromptForNotifications = false});

  final bool showLoginPromptForNotifications;

  @override
  Widget build(BuildContext context) {
    return HomePage(showLoginPromptForNotifications: showLoginPromptForNotifications);
  }
}
