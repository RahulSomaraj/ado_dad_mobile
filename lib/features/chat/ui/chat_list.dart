import 'package:ado_dad_user/features/chat/bloc/chat_bloc.dart';
import 'package:ado_dad_user/features/chat/ui/chat_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatList extends StatefulWidget {
  const ChatList({super.key});

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  void _startNewConversation(BuildContext context) {
    TextEditingController _usernameController = TextEditingController();
    TextEditingController _messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Start a New Conversation"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(hintText: "Enter username"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(hintText: "Enter message"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (_usernameController.text.isNotEmpty &&
                  _messageController.text.isNotEmpty) {
                context.read<ChatBloc>().add(
                      ChatEvent.sendMessage(
                        _usernameController.text,
                        _messageController.text,
                      ),
                    );
                Navigator.pop(context);
              }
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages'),
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state.chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "No messages available",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _startNewConversation(context),
                    child: const Text("Start a New Conversation"),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: state.chats.length,
            itemBuilder: (context, index) {
              final chat = state.chats[index];
              return ListTile(
                leading:
                    CircleAvatar(backgroundImage: NetworkImage(chat["image"])),
                title: Text(chat["username"],
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(chat["message"]),
                trailing: chat["unread"] > 0
                    ? CircleAvatar(
                        backgroundColor: Colors.blue,
                        radius: 10,
                        child: Text(chat["unread"].toString(),
                            style: TextStyle(color: Colors.white)),
                      )
                    : SizedBox(),
                onTap: () {
                  context
                      .read<ChatBloc>()
                      .add(ChatEvent.markChatAsRead(chat["username"]));
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(chat["username"]),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _startNewConversation(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
