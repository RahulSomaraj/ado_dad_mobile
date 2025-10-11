/// Configuration class for chat socket service
class ChatConfig {
  final String baseUrl;
  final int reconnectionAttempts;
  final int timeout;
  final bool reconnection;

  const ChatConfig({
    this.baseUrl = 'https://api.example.com',
    this.reconnectionAttempts = 3,
    this.timeout = 10000,
    this.reconnection = true,
  });
}
