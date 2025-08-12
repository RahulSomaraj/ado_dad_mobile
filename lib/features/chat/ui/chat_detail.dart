import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat_bloc.dart';

class ChatDetailScreen extends StatelessWidget {
  final String username;
  ChatDetailScreen(this.username);

  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(username)),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                return ListView.builder(
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final isUser =
                        state.messages[index]["username"] == username;
                    return Align(
                      alignment:
                          isUser ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        padding: EdgeInsets.all(10),
                        margin:
                            EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.grey[200] : Colors.blue[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(state.messages[index]["message"]!),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          TextField(controller: _messageController),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              context.read<ChatBloc>().add(
                  ChatEvent.sendMessage(username, _messageController.text));
              _messageController.clear();
            },
          ),
        ],
      ),
    );
  }
}
