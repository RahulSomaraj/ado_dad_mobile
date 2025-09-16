# Chat Socket Implementation

This document explains the socket implementation for the chat functionality in the Flutter app.

## Overview

The chat system uses Socket.IO for real-time communication with JWT authentication. The implementation includes:

- **Socket Service**: Handles WebSocket connections and events
- **Chat Models**: Data models for messages, threads, and events
- **Chat Bloc**: State management for chat functionality
- **UI Integration**: Updated chat UI with real-time features

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Chat UI       │    │   Chat Bloc      │    │ Socket Service  │
│                 │    │                  │    │                 │
│ - ChatThreadPage│◄──►│ - State Mgmt     │◄──►│ - Connection    │
│ - MessagesPage  │    │ - Event Handling │    │ - Event Listeners│
│ - Test Page     │    │ - Message Flow   │    │ - JWT Auth      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │   Chat Models    │
                       │                  │
                       │ - ChatMessage    │
                       │ - ChatThread     │
                       │ - Socket Events  │
                       └──────────────────┘
```

## Key Components

### 1. Socket Service (`ChatSocketService`)

Located at: `lib/features/chat/services/chat_socket_service.dart`

**Features:**
- JWT token authentication
- Connection state management
- Event streaming for real-time updates
- Automatic reconnection
- Thread-based messaging

**Key Methods:**
```dart
// Connect to chat socket
await socketService.connect();

// Send a message
await socketService.sendMessage(
  threadId: 'thread_123',
  message: 'Hello!',
  messageType: 'text',
);

// Join a thread
await socketService.joinThread('thread_123');

// Leave a thread
await socketService.leaveThread('thread_123');
```

### 2. Chat Models

Located at: `lib/features/chat/models/chat_models.dart`

**Main Models:**
- `ChatMessage`: Individual chat messages
- `ChatThread`: Chat conversation threads
- `ChatSocketEvent`: Socket event wrapper
- `TypingIndicator`: Real-time typing status
- `ChatParticipant`: User information in chats

### 3. Chat Bloc

Located at: `lib/features/chat/bloc/chat_bloc.dart`

**State Management:**
- Connection state tracking
- Message management
- Thread handling
- Typing indicators
- Error handling

**Key Events:**
```dart
// Connect to chat
context.read<ChatBloc>().add(const ChatEvent.connect());

// Send message
context.read<ChatBloc>().add(ChatEvent.sendMessage(
  threadId: 'thread_123',
  content: 'Hello!',
  messageType: 'text',
));

// Join thread
context.read<ChatBloc>().add(ChatEvent.joinThread('thread_123'));
```

## Usage

### 1. Basic Setup

The ChatBloc is already provided in the main app:

```dart
// In main.dart
BlocProvider<ChatBloc>(
  create: (context) => ChatBloc(),
),
```

### 2. Using in UI

```dart
// In your widget
class MyChatWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        return Column(
          children: [
            // Connection status
            Text('Status: ${state.connectionState}'),
            
            // Messages
            Expanded(
              child: ListView.builder(
                itemCount: state.currentThreadMessages.length,
                itemBuilder: (context, index) {
                  final message = state.currentThreadMessages[index];
                  return Text(message.content);
                },
              ),
            ),
            
            // Send message
            ElevatedButton(
              onPressed: () {
                context.read<ChatBloc>().add(ChatEvent.sendMessage(
                  threadId: 'my_thread',
                  content: 'Hello!',
                ));
              },
              child: Text('Send Message'),
            ),
          ],
        );
      },
    );
  }
}
```

### 3. Testing the Connection

A test page is available at `/chat-test` route that allows you to:

- Test socket connection
- Send test messages
- View connection status
- Monitor real-time events

Navigate to the test page to verify the socket implementation is working correctly.

## Socket Events

The implementation handles these socket events:

### Client → Server Events
- `send_message`: Send a message to a thread
- `join_thread`: Join a specific chat thread
- `leave_thread`: Leave a chat thread
- `typing`: Send typing indicator
- `stop_typing`: Stop typing indicator

### Server → Client Events
- `new_message`: New message received
- `message_sent`: Message sent confirmation
- `typing`: User is typing
- `stop_typing`: User stopped typing
- `user_joined`: User joined thread
- `user_left`: User left thread

## Configuration

### Environment Variables

The socket connects to the chat namespace at:
```
${Env.baseUrl}/chat
```

Where `Env.baseUrl` is defined in `lib/env/env.dart` (default: `https://uat.ado-dad.com`)

### JWT Authentication

The socket automatically includes the JWT token from SharedPreferences:

```dart
// Token is retrieved from SharedPreferences
final token = await getToken();
```

## Error Handling

The implementation includes comprehensive error handling:

- Connection failures
- Authentication errors
- Network issues
- Message sending failures

Errors are exposed through the ChatBloc state and can be displayed in the UI.

## Real-time Features

1. **Live Messages**: Messages appear instantly when received
2. **Typing Indicators**: Shows when users are typing
3. **Connection Status**: Visual indicators for connection state
4. **Auto-reconnection**: Automatically reconnects on connection loss
5. **Message Status**: Tracks message delivery and read status

## Thread Management

Each chat conversation is organized into threads:

- Users can join/leave threads
- Messages are scoped to specific threads
- Typing indicators are thread-specific
- Unread message counts per thread

## Security

- JWT token authentication for all socket connections
- Token validation on the server side
- Secure WebSocket connections (WSS in production)
- User authorization for thread access

## Performance Considerations

- Efficient message batching
- Connection pooling
- Automatic cleanup of resources
- Optimized state updates
- Memory management for large message lists

## Troubleshooting

### Common Issues

1. **Connection Failed**
   - Check JWT token validity
   - Verify network connectivity
   - Confirm server is running

2. **Messages Not Sending**
   - Ensure connected to socket
   - Check thread ID validity
   - Verify user permissions

3. **Real-time Updates Not Working**
   - Check socket event listeners
   - Verify BlocBuilder is properly set up
   - Confirm state updates are being emitted

### Debug Mode

Enable debug logging by checking the console output. The socket service logs all connection events and message flows.

## Future Enhancements

Potential improvements for the chat system:

1. **Message Encryption**: End-to-end encryption for messages
2. **File Sharing**: Support for image/file attachments
3. **Voice Messages**: Audio message support
4. **Message Search**: Search functionality within threads
5. **Push Notifications**: Background message notifications
6. **Message Reactions**: Emoji reactions to messages
7. **Message Threading**: Reply to specific messages
8. **Group Chats**: Multi-user chat rooms
9. **Message Scheduling**: Send messages at specific times
10. **Message Translation**: Auto-translate messages

## API Integration

The socket implementation is designed to work with a Socket.IO server that supports:

- JWT authentication middleware
- Chat namespace (`/chat`)
- Thread-based messaging
- Real-time event broadcasting
- User presence tracking

Ensure your backend server implements the corresponding event handlers for the client events listed above.
