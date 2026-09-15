// One shared audio player for all voice notes (F-25): starting one note stops
// the previous; bytes are cached on disk by LockCachingAudioSource.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class VoicePlayback {
  const VoicePlayback({this.url, this.playing = false, this.loading = false, this.position = Duration.zero, this.duration});

  final String? url;
  final bool playing;
  final bool loading;
  final Duration position;
  final Duration? duration;

  bool isFor(String u) => url == u;
}

class ChatAudioController {
  ChatAudioController._();
  static final ChatAudioController instance = ChatAudioController._();

  final ValueNotifier<VoicePlayback> state = ValueNotifier(const VoicePlayback());
  AudioPlayer? _player;
  final List<StreamSubscription<dynamic>> _subs = [];

  AudioPlayer get _p {
    final existing = _player;
    if (existing != null) return existing;
    final p = AudioPlayer();
    _subs
      ..add(p.playerStateStream.listen((s) {
        if (s.processingState == ProcessingState.completed) {
          p.pause();
          p.seek(Duration.zero);
          state.value = VoicePlayback(url: state.value.url, duration: state.value.duration);
          return;
        }
        state.value = VoicePlayback(
          url: state.value.url,
          playing: s.playing,
          loading: s.processingState == ProcessingState.loading || s.processingState == ProcessingState.buffering,
          position: state.value.position,
          duration: state.value.duration,
        );
      }))
      ..add(p.positionStream.listen((pos) {
        final v = state.value;
        state.value = VoicePlayback(url: v.url, playing: v.playing, loading: v.loading, position: pos, duration: v.duration);
      }))
      ..add(p.durationStream.listen((d) {
        final v = state.value;
        state.value = VoicePlayback(url: v.url, playing: v.playing, loading: v.loading, position: v.position, duration: d);
      }));
    return _player = p;
  }

  Future<void> toggle(String url) async {
    final p = _p;
    final v = state.value;
    if (v.isFor(url)) {
      if (v.playing) {
        await p.pause();
      } else {
        await p.play();
      }
      return;
    }
    await p.stop();
    state.value = VoicePlayback(url: url, loading: true);
    try {
      // Caches voice notes on disk so replays don't re-download (F-27).
      // ignore: experimental_member_use
      await p.setAudioSource(LockCachingAudioSource(Uri.parse(url)));
      unawaited(p.play());
    } catch (_) {
      state.value = const VoicePlayback();
      rethrow;
    }
  }

  Future<void> stop() async {
    await _player?.stop();
    state.value = const VoicePlayback();
  }

  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    await _player?.dispose();
    _player = null;
    state.value = const VoicePlayback();
  }
}
