// Screens 01–05 — pure view: renders a ChatListState, reports intent via callbacks.
// The page (chat_list_page.dart) wires it to ChatListCubit; the preview harness
// renders it with fixtures for design QA.

import 'package:flutter/material.dart';

import '../data/chat_models.dart';
import '../state/chat_list_cubit.dart';
import '../widgets/chat_list_controls.dart';
import '../widgets/chat_skeletons.dart';
import '../widgets/chat_state_views.dart';
import '../widgets/chat_tokens.dart';
import '../widgets/conversation_tile.dart';

class ChatListView extends StatelessWidget {
  const ChatListView({
    super.key,
    required this.state,
    required this.myUserId,
    required this.searchController,
    required this.searchFocus,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onFilter,
    required this.onQuery,
    required this.onClearQuery,
    required this.onOpenRoom,
    required this.onBrowse,
    required this.onPostAd,
    this.onBack,
    this.onRoomLongPress,
    this.bottomPadding = 0,
  });

  final ChatListState state;
  final String? myUserId;
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final ValueChanged<ChatListFilter> onFilter;
  final ValueChanged<String> onQuery;
  final VoidCallback onClearQuery;
  final ValueChanged<ChatRoom> onOpenRoom;
  final VoidCallback onBrowse;
  final VoidCallback onPostAd;

  /// Shown in search mode (screen 05) to leave search.
  final VoidCallback? onBack;

  /// Long-press on a row → actions sheet (archive / mark unread).
  final ValueChanged<ChatRoom>? onRoomLongPress;

  /// Space for the floating nav bar when hosted in the tab shell.
  final double bottomPadding;

  bool get _searching => state.query.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    return ColoredBox(
      color: c.surface,
      child: Column(
        children: [
          _Header(
            searching: _searching || searchFocus.hasFocus,
            controller: searchController,
            focus: searchFocus,
            onQuery: onQuery,
            onClear: onClearQuery,
            onBack: onBack,
          ),
          if (!_searching)
            Container(
              padding: const EdgeInsets.only(bottom: 13),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(bottom: BorderSide(color: c.divider, width: 0.7)),
              ),
              child: ChatFilterChips(selected: state.filter, unreadCount: state.unreadRooms, onSelected: onFilter),
            ),
          SizedBox(
            height: ChatSize.progressLine,
            child: state.status == ChatListStatus.refreshing
                ? LinearProgressIndicator(minHeight: ChatSize.progressLine, color: c.brand, backgroundColor: c.divider)
                : null,
          ),
          if (state.failure != null && state.rooms.isNotEmpty)
            ChatBanner(
              text: 'Showing saved chats',
              icon: Icons.cloud_off_rounded,
              tone: ChatBannerTone.warn,
              actionLabel: 'Retry',
              onAction: () => onRefresh(),
            ),
          Expanded(child: _body(context, c)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, ChatColors c) {
    if (state.status == ChatListStatus.loading && state.rooms.isEmpty) {
      return const SingleChildScrollView(physics: NeverScrollableScrollPhysics(), child: ConversationSkeletonList());
    }
    if (state.status == ChatListStatus.error && state.rooms.isEmpty) {
      return ChatErrorView.forList(state.failure, () => onRefresh());
    }

    final rooms = state.visibleRooms;
    if (rooms.isEmpty) {
      if (_searching) {
        return state.searchingRemote
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
            : ChatListNoResultsView(
                title: 'No chats match "${state.query.trim()}"',
                body: 'Try a name, an ad title or words from a message.',
              );
      }
      if (state.filter != ChatListFilter.all) {
        final label = switch (state.filter) {
          ChatListFilter.unread => 'No unread chats',
          ChatListFilter.buying => 'You haven\'t messaged any sellers yet',
          ChatListFilter.selling => 'No one has asked about your ads yet',
          ChatListFilter.all => '',
        };
        return RefreshIndicator(
          onRefresh: onRefresh,
          color: c.brand,
          child: ChatListNoResultsView(
            title: label,
            body: 'You\'re all caught up.',
            actionLabel: 'Show all chats',
            onAction: () => onFilter(ChatListFilter.all),
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: c.brand,
        child: ChatListEmptyView(onBrowse: onBrowse, onPostAd: onPostAd),
      );
    }

    final showFooter = !_searching && (state.hasMore || state.loadMoreFailed || state.status == ChatListStatus.loadingMore);
    final header = _searching ? 1 : 0;

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (!_searching && n.metrics.extentAfter < 500 && state.hasMore && state.status == ChatListStatus.loaded) {
          onLoadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: onRefresh,
        color: c.brand,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: bottomPadding),
          itemCount: header + rooms.length + (showFooter ? 1 : 0) + (_searching && state.searchingRemote ? 1 : 0),
          itemBuilder: (context, index) {
            if (_searching && index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(ChatSize.gutter, 13, ChatSize.gutter, 5),
                child: Text(
                  '${rooms.length} ${rooms.length == 1 ? 'CHAT' : 'CHATS'}',
                  style: TextStyle(fontSize: ChatSize.groupLabelFont, letterSpacing: 0.8, color: c.muted),
                ),
              );
            }
            final i = index - header;
            if (i < rooms.length) {
              final room = rooms[i];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (i > 0) Divider(height: 0.7, thickness: 0.7, indent: ChatSize.dividerInset, color: c.divider),
                  ConversationTile(
                    key: ValueKey(room.roomId),
                    room: room,
                    myUserId: myUserId,
                    highlight: state.query,
                    onTap: () => onOpenRoom(room),
                    onLongPress: onRoomLongPress == null ? null : () => onRoomLongPress!(room),
                  ),
                ],
              );
            }
            if (_searching) {
              return Padding(
                padding: const EdgeInsets.all(ChatSize.gutter),
                child: Row(children: [
                  const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text('Searching older chats…',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: ChatSize.adLineFont, color: c.muted)),
                  ),
                ]),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: state.loadMoreFailed
                    ? TextButton(
                        onPressed: onLoadMore,
                        child: Text('Couldn\'t load more · Retry',
                            style: TextStyle(color: c.brandText, fontSize: ChatSize.adLineFont)),
                      )
                    : const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2)),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.searching,
    required this.controller,
    required this.focus,
    required this.onQuery,
    required this.onClear,
    this.onBack,
  });

  final bool searching;
  final TextEditingController controller;
  final FocusNode focus;
  final ValueChanged<String> onQuery;
  final VoidCallback onClear;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    return Material(
      color: c.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(ChatSize.gutter, 8, ChatSize.gutter, 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!searching) ...[
                Text(
                  'Chats',
                  style: TextStyle(
                    fontSize: ChatSize.listTitle,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.25,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  if (searching)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: IconButton(
                        tooltip: 'Close search',
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          focus.unfocus();
                          onClear();
                          onBack?.call();
                        },
                        icon: Icon(Icons.arrow_back_rounded, color: c.text2, size: ChatSize.headerIcon),
                      ),
                    ),
                  Expanded(
                    child: ChatSearchField(controller: controller, focusNode: focus, onChanged: onQuery, onClear: onClear),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
