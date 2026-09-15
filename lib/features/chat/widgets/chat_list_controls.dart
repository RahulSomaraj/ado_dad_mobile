// Screen 01/05 header controls: search field + filter chips.

import 'package:flutter/material.dart';

import '../state/chat_list_cubit.dart';
import 'chat_tokens.dart';

class ChatSearchField extends StatelessWidget {
  const ChatSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([controller, focusNode]),
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        return AnimatedContainer(
          duration: ChatMotion.fast,
          decoration: BoxDecoration(
            color: c.chip,
            borderRadius: BorderRadius.circular(ChatSize.searchRadius),
            border: Border.all(color: focused ? c.brand : Colors.transparent, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: ChatSize.searchIcon + 2, color: c.muted),
              const SizedBox(width: 9),
              Expanded(
                child: TextField(
                  key: const Key('chat-search'),
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: onChanged,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(fontSize: ChatSize.searchFont, color: c.text),
                  cursorColor: c.brand,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    // 7 px wireframe padding → 9 dp; the 1.5 dp focus ring adds the rest.
                    contentPadding: EdgeInsets.symmetric(vertical: ChatSize.searchPadding.vertical / 2),
                    hintText: 'Search people or ads',
                    hintStyle: TextStyle(fontSize: ChatSize.searchFont, color: c.muted),
                  ),
                ),
              ),
              if (controller.text.isNotEmpty)
                GestureDetector(
                  onTap: onClear,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: ChatSize.searchIcon + 2, color: c.muted),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class ChatFilterChips extends StatelessWidget {
  const ChatFilterChips({
    super.key,
    required this.selected,
    required this.unreadCount,
    required this.onSelected,
  });

  final ChatListFilter selected;
  final int unreadCount;
  final ValueChanged<ChatListFilter> onSelected;

  static const _labels = {
    ChatListFilter.all: 'All',
    ChatListFilter.unread: 'Unread',
    ChatListFilter.buying: 'Buying',
    ChatListFilter.selling: 'Selling',
  };

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: ChatSize.gutter),
      child: Row(
        children: [
          for (final f in ChatListFilter.values) ...[
            if (f != ChatListFilter.all) const SizedBox(width: ChatSize.chipGap),
            _Chip(
              label: _labels[f]!,
              count: f == ChatListFilter.unread && unreadCount > 0 ? unreadCount : null,
              selected: f == selected,
              colors: c,
              onTap: () => onSelected(f),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.colors, required this.onTap, this.count});

  final String label;
  final int? count;
  final bool selected;
  final ChatColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? colors.onBrand : colors.text2;
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: ChatMotion.fast,
          padding: ChatSize.chipPadding,
          decoration: BoxDecoration(
            color: selected ? colors.brand : colors.chip,
            borderRadius: BorderRadius.circular(ChatSize.chipRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(fontSize: ChatSize.chipFont, color: fg, height: 1.3)),
              if (count != null) ...[
                const SizedBox(width: 6),
                Text('$count', style: TextStyle(fontSize: ChatSize.chipCountFont, color: fg, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
