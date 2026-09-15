// Design-QA harness for the chat redesign.
//
//   flutter run -t lib/main_chat_preview.dart
//
// Renders every wireframe state (docs/chat_redesign_wireframes.html, screens
// 01–14) from fixtures — no login, backend or socket needed. Compare each
// screen side by side with the wireframe on a 360 dp device (e.g. Pixel 4a /
// "Small Phone" emulator) in light and dark. Not part of the production app.

import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_theme.dart';
import 'package:ado_dad_user/features/chat/widgets/chat_room_actions_sheet.dart';
import 'package:flutter/material.dart';

import 'features/chat/pages/chat_list_view.dart';
import 'features/chat/pages/chat_thread_view.dart';
import 'features/chat/preview/chat_preview_fixtures.dart' as fx;
import 'features/chat/state/chat_list_cubit.dart';
import 'features/chat/state/chat_thread_cubit.dart';
import 'features/chat/widgets/chat_details_sheet.dart';

void main() => runApp(const ChatPreviewApp());

class ChatPreviewApp extends StatefulWidget {
  const ChatPreviewApp({super.key});

  @override
  State<ChatPreviewApp> createState() => _ChatPreviewAppState();
}

class _ChatPreviewAppState extends State<ChatPreviewApp> {
  ThemeMode _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat design QA',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _mode,
      builder: (context, child) {
        AppColors.brightness = Theme.of(context).brightness;
        return child!;
      },
      home: _Index(
        dark: _mode == ThemeMode.dark,
        onToggleTheme: () => setState(() => _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark),
      ),
    );
  }
}

class _Screen {
  const _Screen(this.no, this.title, this.builder);
  final String no;
  final String title;
  final Widget Function(BuildContext) builder;
}

class _Index extends StatelessWidget {
  const _Index({required this.dark, required this.onToggleTheme});
  final bool dark;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final screens = <_Screen>[
      _Screen('01', 'Chat list — default', (_) => _ListHost(state: fx.listDefault)),
      _Screen('02', 'Chat list — loading', (_) => const _ListHost(state: fx.listLoading)),
      _Screen('03', 'Chat list — empty', (_) => const _ListHost(state: fx.listEmpty)),
      _Screen('04', 'Chat list — error', (_) => const _ListHost(state: fx.listError)),
      _Screen('05', 'Chat list — search', (_) => _ListHost(state: fx.listSearch, query: 'swift')),
      _Screen('06', 'Chat — default', (_) => _ThreadHost(state: fx.threadDefault)),
      _Screen('07', 'Chat — loading', (_) => _ThreadHost(state: fx.threadLoading)),
      _Screen('08', 'Chat — new conversation', (_) => _ThreadHost(state: fx.threadEmpty)),
      _Screen('09', 'Chat — sending', (_) => _ThreadHost(state: fx.threadSending)),
      _Screen('10', 'Chat — failed message', (_) => _ThreadHost(state: fx.threadFailed)),
      _Screen('11', 'Chat — offline / queued', (_) => _ThreadHost(state: fx.threadOffline)),
      _Screen('12', 'Chat — attachments', (_) => _ThreadHost(state: fx.threadAttachments)),
      _Screen('13', 'Chat details sheet', (_) => _ThreadHost(state: fx.threadDetails, openDetails: true)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat design QA'),
        actions: [
          IconButton(
            tooltip: '14 · Toggle dark mode',
            onPressed: onToggleTheme,
            icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: screens.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final s = screens[i];
          return ListTile(
            leading: Text(s.no, style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
            title: Text(s.title),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (ctx) => Scaffold(body: s.builder(ctx)))),
          );
        },
      ),
    );
  }
}

class _ListHost extends StatefulWidget {
  const _ListHost({required this.state, this.query = ''});
  final ChatListState state;
  final String query;

  @override
  State<_ListHost> createState() => _ListHostState();
}

class _ListHostState extends State<_ListHost> {
  late final _search = TextEditingController(text: widget.query);
  final _focus = FocusNode();
  late ChatListState _state = widget.state;

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChatListView(
        state: _state,
        myUserId: fx.me,
        searchController: _search,
        searchFocus: _focus,
        onRefresh: () async => Future<void>.delayed(const Duration(milliseconds: 600)),
        onLoadMore: () {},
        onFilter: (f) => setState(() => _state = _state.copyWith(filter: f)),
        onQuery: (q) => setState(() => _state = _state.copyWith(query: q)),
        onClearQuery: () => setState(() {
          _search.clear();
          _state = _state.copyWith(query: '');
        }),
        onOpenRoom: (_) => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => Scaffold(body: _ThreadHost(state: fx.threadDefault))),
        ),
        onBrowse: () {},
        onPostAd: () {},
        onRoomLongPress: (room) => showChatRoomActions(context, room),
      );
}

class _ThreadHost extends StatefulWidget {
  const _ThreadHost({required this.state, this.openDetails = false});
  final ChatThreadState state;
  final bool openDetails;

  @override
  State<_ThreadHost> createState() => _ThreadHostState();
}

class _ThreadHostState extends State<_ThreadHost> {
  final _composer = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.openDetails) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _details());
    }
  }

  void _details() => showChatDetailsSheet(
        context,
        room: widget.state.room!,
        onCall: () {},
        onViewProfile: () {},
        onViewAd: () {},
        onReport: () {},
      );

  @override
  void dispose() {
    _composer.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChatThreadView(
        state: widget.state,
        composerController: _composer,
        composerFocus: _focus,
        callbacks: ChatThreadCallbacks(
          onBack: () => Navigator.of(context).maybePop(),
          onOpenDetails: _details,
          onOpenAd: () {},
          onCall: () {},
          onRetryLoad: () {},
          onLoadOlder: () {},
          onSendText: (_) {},
          onSendImages: (_, __) {},
          onSendVoice: (_, __, ___) {},
          onRetryMessage: (_) {},
          onEditMessage: (_) {},
          onDeleteMessage: (_) {},
          onOpenImage: (_) {},
        ),
      );
}
