// Chat thread (screens 06–13): wires ChatThreadView to ChatThreadCubit,
// lifecycle (mark-read only while visible), navigation and platform actions.

import 'dart:typed_data';

import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/chat_models.dart';
import '../state/chat_thread_cubit.dart';
import '../widgets/chat_audio_controller.dart';
import '../widgets/chat_details_sheet.dart';
import '../widgets/message_composer.dart';
import 'chat_thread_view.dart';

class ChatThreadPage extends StatelessWidget {
  const ChatThreadPage({super.key, required this.roomId, this.initialRoom});

  final String roomId;

  /// Passed as `extra` from the list / ad detail so the header paints instantly.
  final ChatRoom? initialRoom;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatThreadCubit(roomId: roomId, initialRoom: initialRoom)..open(),
      child: const _ChatThreadScreen(),
    );
  }
}

class _ChatThreadScreen extends StatefulWidget {
  const _ChatThreadScreen();

  @override
  State<_ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<_ChatThreadScreen> with WidgetsBindingObserver {
  final _composer = TextEditingController();
  final _composerFocus = FocusNode();
  bool _openingAd = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ChatAudioController.instance.stop();
    _composer.dispose();
    _composerFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    context.read<ChatThreadCubit>().setVisible(state == AppLifecycleState.resumed);
  }

  ChatThreadCubit get _cubit => context.read<ChatThreadCubit>();

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/chat-rooms');
    }
  }

  Future<void> _call(ChatRoom room) async {
    final number = room.otherUser?.dialNumber;
    if (number == null) return;
    final uri = Uri(scheme: 'tel', path: number);
    if (!await launchUrl(uri) && mounted) {
      _toast('Couldn\'t open the phone app.');
    }
  }

  Future<void> _openAd(ChatRoom room) async {
    final ad = room.ad;
    if (ad == null || _openingAd) return;
    if (ad.availability == AdAvailability.unavailable) {
      _toast('This ad is no longer available.');
      return;
    }
    setState(() => _openingAd = true);
    try {
      final detail = await AddRepository().fetchAdDetail(ad.id);
      if (mounted) context.push('/add-detail-page', extra: detail);
    } catch (_) {
      _toast('Couldn\'t open this ad. Try again.');
    } finally {
      if (mounted) setState(() => _openingAd = false);
    }
  }

  void _openImage(String url) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0),
        body: PhotoView(
          imageProvider: CachedNetworkImageProvider(url),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
        ),
      ),
    ));
  }

  void _details(ChatRoom room) {
    showChatDetailsSheet(
      context,
      room: room,
      onCall: room.otherUser?.dialNumber != null ? () => _call(room) : null,
      onViewProfile: room.otherUser != null ? () => context.push('/seller-profile/${room.otherUser!.id}') : null,
      onViewAd: () => _openAd(room),
      onReport: () => _toast('Reporting from chat is coming soon.'),
    );
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: BlocBuilder<ChatThreadCubit, ChatThreadState>(
        builder: (context, state) {
          final room = state.room;
          return ChatThreadView(
            state: state,
            composerController: _composer,
            composerFocus: _composerFocus,
            callbacks: ChatThreadCallbacks(
              onBack: _back,
              onOpenDetails: () {
                if (room != null) _details(room);
              },
              onOpenAd: () {
                if (room != null) _openAd(room);
              },
              onCall: room?.otherUser?.dialNumber != null ? () => _call(room!) : null,
              onRetryLoad: _cubit.retryLoad,
              onLoadOlder: _cubit.loadOlder,
              onSendText: _cubit.sendText,
              onSendImages: (List<PickedChatImage> images, String caption) {
                for (var i = 0; i < images.length; i++) {
                  final img = images[i];
                  _cubit.sendImage(
                    img.bytes,
                    img.mimeType,
                    width: img.width,
                    height: img.height,
                    caption: i == images.length - 1 ? caption : '',
                  );
                }
              },
              onSendVoice: (Uint8List bytes, String mime, int seconds) => _cubit.sendVoice(bytes, mime, seconds),
              onRetryMessage: _cubit.retry,
              onEditMessage: (m) {
                _cubit.discard(m);
                _composer
                  ..text = m.content
                  ..selection = TextSelection.collapsed(offset: m.content.length);
                _composerFocus.requestFocus();
              },
              onDeleteMessage: _cubit.discard,
              onOpenImage: _openImage,
            ),
          );
        },
      ),
    );
  }
}
