import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  void connect() {
    socket = IO.io(
        'https://uat.ado-dad.com',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build());

    socket.connect();

    socket.onConnect((_) {
      print('Connected to server');
    });

    socket.onDisconnect((_) {
      print('Disconnected from server');
    });
  }

  void sendMessage(String username, String message) {
    socket.emit('send_message', {'username': username, 'message': message});
  }

  void listenToMessages(Function(Map<String, dynamic>) onMessageReceived) {
    socket.on('receive_message', (data) {
      onMessageReceived(data);
    });
  }

  void listenToChatList(Function(List<dynamic>) onChatListUpdated) {
    socket.on('chat_list', (data) {
      onChatListUpdated(List<Map<String, dynamic>>.from(data));
    });
  }

  void markChatAsRead(String username) {
    socket.emit('mark_read', username);
  }

  void disconnect() {
    socket.disconnect();
  }
}
