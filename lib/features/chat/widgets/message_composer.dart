// Screens 06/11/12 composer: + attach · pill field · mic (hold) ↔ send,
// image tray with caption and "Send N", voice recording bar with 3:00 cap.

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'chat_copy.dart';
import 'chat_format.dart';
import 'chat_tokens.dart';

class PickedChatImage {
  const PickedChatImage({required this.bytes, required this.mimeType, this.width, this.height});
  final Uint8List bytes;
  final String mimeType;
  final int? width;
  final int? height;
}

class MessageComposer extends StatefulWidget {
  const MessageComposer({
    super.key,
    required this.controller,
    required this.onSendText,
    required this.onSendImages,
    required this.onSendVoice,
    this.closed = false,
    this.attachmentsEnabled = true,
    this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onSendText;
  final void Function(List<PickedChatImage> images, String caption) onSendImages;
  final void Function(Uint8List bytes, String mimeType, int seconds) onSendVoice;

  /// Room closed / ad unavailable: show a notice instead of the input.
  final bool closed;

  /// Attachments need a connection (uploads) — disabled while offline.
  final bool attachmentsEnabled;

  static const maxImages = 6;
  static const maxVoiceSeconds = 180;

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final List<PickedChatImage> _staged = [];
  AudioRecorder? _recorder; // created on first use (no plugin call in tests)
  bool _pressActive = false;
  Timer? _ticker;
  bool _recording = false;
  bool _cancelArmed = false;
  int _seconds = 0;
  String? _recordPath;
  double _dragDx = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(covariant MessageComposer old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _ticker?.cancel();
    _recorder?.dispose();
    super.dispose();
  }

  void _onText() => setState(() {});

  bool get _hasText => widget.controller.text.trim().isNotEmpty;

  // ---- send ------------------------------------------------------------------

  void _send() {
    if (_staged.isNotEmpty) {
      widget.onSendImages(List.of(_staged), widget.controller.text.trim());
      setState(_staged.clear);
      widget.controller.clear();
      return;
    }
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    widget.onSendText(text);
    widget.controller.clear();
  }

  // ---- images ------------------------------------------------------------------

  Future<void> _pickImages() async {
    final c = ChatColors.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      backgroundColor: c.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera_outlined, color: c.brandText),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.image_outlined, color: c.brandText),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final remaining = MessageComposer.maxImages - _staged.length;
    if (remaining <= 0) return;
    List<XFile> files;
    try {
      if (source == ImageSource.camera) {
        final f = await picker.pickImage(source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 80);
        files = f == null ? const [] : [f];
      } else {
        files = await picker.pickMultiImage(
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 80,
          limit: remaining >= 2 ? remaining : null, // image_picker requires limit > 1
        );
      }
    } catch (_) {
      _toast('Couldn\'t open photos. Check the app\'s permissions.');
      return;
    }

    final picked = <PickedChatImage>[];
    for (final f in files.take(remaining)) {
      final bytes = await f.readAsBytes();
      int? w;
      int? h;
      try {
        final img = await decodeImageFromList(bytes);
        w = img.width;
        h = img.height;
        img.dispose();
      } catch (_) {}
      picked.add(PickedChatImage(bytes: bytes, mimeType: _mimeFor(f.path), width: w, height: h));
    }
    if (!mounted || picked.isEmpty) return;
    setState(() => _staged.addAll(picked));
  }

  static String _mimeFor(String path) {
    switch (p.extension(path).toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.heic':
      case '.heif':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  // ---- voice -------------------------------------------------------------------

  Future<void> _startRecording() async {
    if (_recording) return;
    final rec = _recorder ??= AudioRecorder();
    try {
      if (!await rec.hasPermission()) {
        _toast('Allow microphone access to send voice messages.');
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = p.join(dir.path, 'chat_voice_${DateTime.now().millisecondsSinceEpoch}.m4a');
      await rec.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 44100, numChannels: 1, bitRate: 64000),
        path: path,
      );
      // Page closed or finger lifted while the recorder was starting.
      if (!mounted || !_pressActive) {
        await rec.cancel();
        return;
      }
      HapticFeedback.mediumImpact();
      setState(() {
        _recording = true;
        _cancelArmed = false;
        _seconds = 0;
        _recordPath = path;
        _dragDx = 0;
      });
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _seconds++);
        if (_seconds >= MessageComposer.maxVoiceSeconds) _finishRecording(send: true);
      });
    } catch (_) {
      _toast('Couldn\'t start recording.');
    }
  }

  Future<void> _finishRecording({required bool send}) async {
    if (!_recording) return;
    _ticker?.cancel();
    final seconds = _seconds;
    final path = _recordPath;
    setState(() {
      _recording = false;
      _cancelArmed = false;
    });
    final rec = _recorder;
    if (rec == null) return;
    try {
      if (!send || seconds < 1) {
        await rec.cancel();
        if (send && seconds < 1) _toast('Hold to record, release to send.');
        return;
      }
      final out = await rec.stop() ?? path;
      if (out == null) return;
      final file = File(out);
      final bytes = await file.readAsBytes();
      widget.onSendVoice(bytes, 'audio/mp4', seconds);
      unawaited(file.delete().catchError((_) => file));
    } catch (_) {
      _toast('Couldn\'t save the recording.');
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }

  // ---- build -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);

    if (widget.closed) {
      return Container(
        color: c.surface,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: SafeArea(
          top: false,
          child: Text(
            ChatCopy.closedComposer,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: ChatSize.bannerFont, color: c.muted),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.divider, width: 0.7))),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_staged.isNotEmpty) _tray(c),
            Padding(
              padding: ChatSize.composerPadding,
              child: _inputRow(c),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tray(ChatColors c) {
    return SizedBox(
      height: ChatSize.trayThumb + 18,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(13, 11, 13, 0),
        children: [
          for (var i = 0; i < _staged.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 9),
              child: SizedBox(
                width: ChatSize.trayThumb,
                height: ChatSize.trayThumb,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(ChatSize.trayRadius),
                      child: Image.memory(_staged[i].bytes,
                          width: ChatSize.trayThumb, height: ChatSize.trayThumb, fit: BoxFit.cover, cacheWidth: 220),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: GestureDetector(
                        onTap: () => setState(() => _staged.removeAt(i)),
                        child: Container(
                          width: ChatSize.trayRemove,
                          height: ChatSize.trayRemove,
                          decoration: BoxDecoration(
                            color: const Color(0xFF16161D),
                            shape: BoxShape.circle,
                            border: Border.all(color: c.surface, width: 2),
                          ),
                          child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_staged.length < MessageComposer.maxImages)
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: ChatSize.trayThumb,
                height: ChatSize.trayThumb,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ChatSize.trayRadius),
                  border: Border.all(color: c.divider),
                ),
                child: Icon(Icons.add_rounded, color: c.muted),
              ),
            ),
        ],
      ),
    );
  }

  Widget _inputRow(ChatColors c) {
    final showSendPill = _staged.isNotEmpty && !_recording;
    final canSend = (_hasText || showSendPill) && !_recording;
    // The mic GestureDetector must stay in the tree for the whole press: if it
    // were swapped out when recording starts, its long-press recogniser would be
    // disposed and onLongPressMoveUpdate / onLongPressEnd would never fire (no
    // slide-to-cancel, and release wouldn't send). Keyed so the Row keeps the
    // same element even though the leading children change.
    final showMic = _recording || (!showSendPill && !canSend);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!showSendPill && !_recording)
          _RoundIcon(
            icon: Icons.add_rounded,
            color: widget.attachmentsEnabled ? c.brandText : c.muted,
            onTap: widget.attachmentsEnabled ? _pickImages : null,
            tooltip: 'Add photos',
          ),
        const SizedBox(width: 4),
        if (_recording)
          Expanded(child: _recordingBar(c))
        else
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: ChatSize.sendButton),
            decoration: BoxDecoration(color: c.chip, borderRadius: BorderRadius.circular(ChatSize.fieldRadius)),
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              minLines: 1,
              maxLines: 5,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              style: TextStyle(fontSize: ChatSize.fieldFont, color: c.text, height: 1.35),
              cursorColor: c.brand,
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: ChatSize.fieldPadding,
                hintText: showSendPill ? 'Add a caption' : 'Message',
                hintStyle: TextStyle(fontSize: ChatSize.fieldFont, color: c.muted),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (showSendPill)
          Material(
            color: c.brand,
            borderRadius: BorderRadius.circular(ChatSize.buttonRadius),
            child: InkWell(
              onTap: _send,
              borderRadius: BorderRadius.circular(ChatSize.buttonRadius),
              child: Container(
                height: ChatSize.sendButton,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Send ${_staged.length}',
                      style: TextStyle(color: c.onBrand, fontSize: ChatSize.fieldFont, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 6),
                  Icon(Icons.send_rounded, size: 16, color: c.onBrand),
                ]),
              ),
            ),
          )
        else if (canSend)
          _SendButton(onTap: _send)
        else if (showMic)
          GestureDetector(
            key: const ValueKey('chat-mic'),
            behavior: HitTestBehavior.opaque,
            onLongPressStart: widget.attachmentsEnabled
                ? (_) {
                    _pressActive = true;
                    _startRecording();
                  }
                : null,
            onLongPressMoveUpdate: (d) {
              _dragDx = d.offsetFromOrigin.dx;
              final armed = _dragDx < -90;
              if (armed != _cancelArmed) setState(() => _cancelArmed = armed);
            },
            onLongPressEnd: (_) {
              _pressActive = false;
              _finishRecording(send: !_cancelArmed);
            },
            onLongPressCancel: () {
              _pressActive = false;
              _finishRecording(send: false);
            },
            onTap: _recording ? null : () => _toast('Hold to record a voice message.'),
            child: _recording
                ? Container(
                    width: ChatSize.sendButton,
                    height: ChatSize.sendButton,
                    decoration: BoxDecoration(color: _cancelArmed ? c.err : c.recording, shape: BoxShape.circle),
                    child: Icon(_cancelArmed ? Icons.delete_outline_rounded : Icons.mic_rounded,
                        color: Colors.white, size: 22),
                  )
                : SizedBox(
                    width: ChatSize.sendButton,
                    height: ChatSize.sendButton,
                    child: Icon(
                      Icons.mic_none_rounded,
                      size: ChatSize.composerIcon,
                      color: widget.attachmentsEnabled ? c.text2 : c.muted,
                      semanticLabel: 'Hold to record',
                    ),
                  ),
          ),
      ],
    );
  }

  Widget _recordingBar(ChatColors c) {
    return SizedBox(
      height: ChatSize.sendButton,
      child: Row(
        children: [
          const SizedBox(width: 10),
          _BlinkDot(color: c.recording),
          const SizedBox(width: 10),
          Text(
            formatDuration(_seconds),
            style: TextStyle(fontSize: ChatSize.fieldFont, color: c.text, fontFeatures: const [ui.FontFeature.tabularFigures()]),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _cancelArmed ? 'Release to cancel' : '‹ Slide left to cancel',
              style: TextStyle(fontSize: ChatSize.bannerFont, color: _cancelArmed ? c.err : c.muted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text('max 3:00', style: TextStyle(fontSize: 12, color: c.muted)),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.color, required this.onTap, required this.tooltip});
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: ChatSize.sendButton,
        height: ChatSize.sendButton,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          icon: Icon(icon, size: ChatSize.composerIcon + 2, color: color),
        ),
      );
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    return Semantics(
      button: true,
      label: 'Send',
      child: Material(
        color: c.brand,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: ChatSize.sendButton,
            height: ChatSize.sendButton,
            child: Icon(Icons.send_rounded, size: 19, color: c.onBrand),
          ),
        ),
      ),
    );
  }
}

class _BlinkDot extends StatefulWidget {
  const _BlinkDot({required this.color});
  final Color color;

  @override
  State<_BlinkDot> createState() => _BlinkDotState();
}

class _BlinkDotState extends State<_BlinkDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0.3).animate(_c),
        child: Container(width: 10, height: 10, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
      );
}
