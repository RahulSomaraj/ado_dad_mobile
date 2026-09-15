// Chat tab (screens 01–05): wires ChatListView to ChatListCubit and navigation.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../data/chat_models.dart';
import '../data/chat_repository.dart';
import '../state/chat_list_cubit.dart';
import '../widgets/chat_room_actions_sheet.dart';
import 'chat_list_view.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatListCubit()..start(),
      child: const _ChatListScreen(),
    );
  }
}

/// Height of the tab shell's floating nav bar (64) plus its margin.
const double _navClearance = 88;

class _ChatListScreen extends StatefulWidget {
  const _ChatListScreen();

  @override
  State<_ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<_ChatListScreen> {
  final _search = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _open(ChatRoom room) {
    context.read<ChatListCubit>().markRoomReadLocally(room.roomId);
    context.push('/chat/${Uri.encodeComponent(room.roomId)}', extra: room);
  }

  Future<void> _actions(ChatRoom room) async {
    final cubit = context.read<ChatListCubit>();
    final action = await showChatRoomActions(context, room);
    if (!mounted || action == null) return;
    final messenger = ScaffoldMessenger.of(context);
    void toast(String text, {SnackBarAction? undo}) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        action: undo,
        behavior: SnackBarBehavior.floating,
        // Clear the floating nav bar of the tab shell.
        margin: const EdgeInsets.fromLTRB(16, 0, 16, _navClearance),
      ));

    switch (action) {
      case ChatRoomAction.archive:
        final archived = await cubit.archive(room);
        if (!mounted) return;
        if (archived) {
          toast('Chat archived', undo: SnackBarAction(label: 'Undo', onPressed: () => cubit.unarchive(room)));
        } else {
          toast('Couldn\'t archive the chat. Try again.');
        }
      case ChatRoomAction.markUnread:
        final marked = await cubit.markUnread(room);
        if (!marked && mounted) toast('Couldn\'t mark as unread. Try again.');
      case ChatRoomAction.markRead:
        await cubit.markRead(room);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChatListCubit>();
    return PopScope(
      canPop: !_focus.hasFocus && _search.text.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _focus.unfocus();
        _search.clear();
        cubit.clearQuery();
      },
      child: Scaffold(
        body: BlocBuilder<ChatListCubit, ChatListState>(
          builder: (context, state) => ChatListView(
            state: state,
            myUserId: ChatRepository.instance.userId,
            searchController: _search,
            searchFocus: _focus,
            onRefresh: cubit.refresh,
            onLoadMore: cubit.loadMore,
            onFilter: cubit.setFilter,
            onQuery: cubit.setQuery,
            onClearQuery: () {
              _search.clear();
              cubit.clearQuery();
            },
            onOpenRoom: _open,
            onRoomLongPress: _actions,
            bottomPadding: _navClearance + MediaQuery.paddingOf(context).bottom,
            onBrowse: () => context.go('/home'),
            onPostAd: () => context.push('/seller'),
          ),
        ),
      ),
    );
  }
}
