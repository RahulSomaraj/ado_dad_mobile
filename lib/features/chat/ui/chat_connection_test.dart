import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_bloc.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_event.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_state.dart';
import 'package:ado_dad_user/features/chat/models/chat_models.dart';
import 'package:ado_dad_user/env/env.dart';

class ChatConnectionTest extends StatelessWidget {
  const ChatConnectionTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Socket Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Connection Status Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connection Status',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    _getConnectionColor(state.connectionState),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(_getConnectionText(state.connectionState)),
                          ],
                        ),
                        if (state.socketId != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Socket ID: ${state.socketId}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Configuration:',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Base URL: ${Env.baseUrl}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'Socket Endpoint: ${Env.baseUrl}/chat',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (state.error != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Error: ${state.error}',
                              style: TextStyle(color: Colors.red.shade800),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: state.connectionState ==
                                SocketConnectionState.connecting
                            ? null
                            : () => context
                                .read<ChatBloc>()
                                .add(const ChatEvent.connect()),
                        child: const Text('Connect'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: state.connectionState ==
                                SocketConnectionState.disconnected
                            ? null
                            : () => context
                                .read<ChatBloc>()
                                .add(const ChatEvent.disconnect()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Disconnect'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                ElevatedButton(
                  onPressed:
                      state.connectionState == SocketConnectionState.connected
                          ? null
                          : () => context
                              .read<ChatBloc>()
                              .add(const ChatEvent.reconnect()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Reconnect'),
                ),

                const SizedBox(height: 24),

                // Test Message Section
                if (state.isConnected) ...[
                  Text(
                    'Test Message',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Enter test message',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (message) {
                            if (message.trim().isNotEmpty) {
                              context
                                  .read<ChatBloc>()
                                  .add(ChatEvent.sendMessage(
                                    threadId: 'test_thread',
                                    content: message.trim(),
                                    messageType: 'text',
                                  ));
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          context
                              .read<ChatBloc>()
                              .add(const ChatEvent.sendMessage(
                                threadId: 'test_thread',
                                content: 'Hello from Flutter!',
                                messageType: 'text',
                              ));
                        },
                        child: const Text('Send Test'),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // Messages List
                if (state.currentThreadMessages.isNotEmpty) ...[
                  Text(
                    'Messages (${state.currentThreadMessages.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.currentThreadMessages.length,
                      itemBuilder: (context, index) {
                        final message = state.currentThreadMessages[index];
                        return Card(
                          child: ListTile(
                            title: Text(message.content),
                            subtitle: Text(
                              'From: ${message.senderName}\n'
                              'Time: ${message.timestamp.toString()}',
                            ),
                            trailing: message.isRead
                                ? const Icon(Icons.done_all, color: Colors.blue)
                                : const Icon(Icons.done, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getConnectionColor(SocketConnectionState state) {
    switch (state) {
      case SocketConnectionState.connected:
        return Colors.green;
      case SocketConnectionState.connecting:
      case SocketConnectionState.reconnecting:
        return Colors.orange;
      case SocketConnectionState.disconnected:
        return Colors.grey;
      case SocketConnectionState.error:
        return Colors.red;
    }
  }

  String _getConnectionText(SocketConnectionState state) {
    switch (state) {
      case SocketConnectionState.connected:
        return 'Connected';
      case SocketConnectionState.connecting:
        return 'Connecting...';
      case SocketConnectionState.reconnecting:
        return 'Reconnecting...';
      case SocketConnectionState.disconnected:
        return 'Disconnected';
      case SocketConnectionState.error:
        return 'Error';
    }
  }
}
