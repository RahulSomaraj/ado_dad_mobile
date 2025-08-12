import 'package:ado_dad_user/models/chat_item.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final ChatItem user;

  const ChatPage({required this.user});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();

  List<Message> messages = [
    Message(text: "Hey there!", isMe: false),
    Message(text: "Hi! How are you?", isMe: true),
    Message(text: "I’m good. What about you?", isMe: false),
  ];

  void sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      messages.add(Message(text: _controller.text.trim(), isMe: true));
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.user.profileUrl),
            ),
            SizedBox(width: 10),
            Text(widget.user.name),
          ],
        ),
      ),
      body: Column(
        children: [
          // 🔄 Message List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              reverse: true,
              itemBuilder: (context, index) {
                final message = messages[messages.length - 1 - index];
                return Align(
                  alignment: message.isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(
                      color:
                          message.isMe ? Colors.green[100] : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: message.isMe
                            ? Radius.circular(16)
                            : Radius.circular(0),
                        bottomRight: message.isMe
                            ? Radius.circular(0)
                            : Radius.circular(16),
                      ),
                    ),
                    child: Text(message.text),
                  ),
                );
              },
            ),
          ),

          // ✍️ Message Input
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.green,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: sendMessage,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Message {
  final String text;
  final bool isMe;

  Message({required this.text, required this.isMe});
}
