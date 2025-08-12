import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/features/chat/ui/chat_page.dart';
import 'package:ado_dad_user/models/chat_item.dart';
import 'package:flutter/material.dart';

class ChatListPage extends StatefulWidget {
  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final List<ChatItem> allChats = [
    ChatItem(
      name: "Alice",
      message: "Hey! Are we still meeting today?",
      time: "10:24 AM",
      unreadCount: 2,
      profileUrl: "https://i.pravatar.cc/150?img=1",
    ),
    ChatItem(
      name: "Bob",
      message: "Got the documents. Thanks!",
      time: "9:47 AM",
      unreadCount: 0,
      profileUrl: "https://i.pravatar.cc/150?img=2",
    ),
    ChatItem(
      name: "Charlie",
      message: "Let’s catch up later!",
      time: "Yesterday",
      unreadCount: 5,
      profileUrl: "https://i.pravatar.cc/150?img=3",
    ),
  ];

  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredChats = allChats
        .where((chat) =>
            chat.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
          title: Text(
        'Messages',
        style: AppTextstyle.appbarText,
      )),
      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),

          // 📃 Chat List or Empty State
          Expanded(
            child: filteredChats.isEmpty
                ? Center(
                    child: Text(
                      allChats.isEmpty
                          ? 'No messages yet'
                          : 'No matching users',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredChats.length,
                    itemBuilder: (context, index) {
                      final chat = filteredChats[index];
                      return ChatListTile(chat: chat);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ChatListTile extends StatelessWidget {
  final ChatItem chat;

  const ChatListTile({required this.chat});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(chat.profileUrl),
        radius: 28,
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(chat.name, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            chat.time,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              chat.message,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          if (chat.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${chat.unreadCount}',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
      onTap: () {
        // Navigate to chat page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(user: chat),
          ),
        );
      },
    );
  }
}
