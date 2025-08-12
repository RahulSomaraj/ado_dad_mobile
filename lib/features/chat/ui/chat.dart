import 'package:ado_dad_user/common/device_checker.dart';
import 'package:ado_dad_user/features/chat/ui/android_chat_mobile.dart';
import 'package:ado_dad_user/features/chat/ui/ios_chat_mobile.dart';
import 'package:flutter/material.dart';

class Chat extends StatelessWidget {
  const Chat({super.key});

  @override
  Widget build(BuildContext context) {
    return DeviceChecker(
      androidTabletView: Scaffold(),
      androidMobileView: AndroidChatMobile(),
      iosTabletView: Scaffold(),
      iosMobileView: IosChatMobile(),
    );
  }
}
