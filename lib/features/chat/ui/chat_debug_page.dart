import 'package:flutter/material.dart';
import 'package:ado_dad_user/repositories/chat_repository.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/config/app_config.dart';

class ChatDebugPage extends StatefulWidget {
  const ChatDebugPage({super.key});

  @override
  State<ChatDebugPage> createState() => _ChatDebugPageState();
}

class _ChatDebugPageState extends State<ChatDebugPage> {
  final ChatRepository _chatRepository = ChatRepository();
  List<String> _logs = [];
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _addLog('🔍 Chat Debug Page Started');
    _checkConfiguration();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} $message');
    });
    print(message);
  }

  Future<void> _checkConfiguration() async {
    _addLog('📋 Checking configuration...');

    // Check base URL
    final baseUrl = AppConfig.baseUrl;
    _addLog('🌐 Base URL: $baseUrl');
    _addLog('🔌 Socket URL: $baseUrl (no /chat path needed)');

    if (baseUrl.isEmpty) {
      _addLog('❌ Base URL is empty!');
      return;
    }

    // Check token
    final token = await getToken();
    _addLog('🔑 Token: ${token != null ? 'Present' : 'Missing'}');

    if (token == null || token.isEmpty) {
      _addLog('❌ No authentication token found!');
      _addLog('💡 Please login first to get a token');
      return;
    }

    _addLog('✅ Configuration looks good');
    _testConnection();
  }

  Future<void> _testConnection() async {
    _addLog('🚀 Testing WebSocket connection...');

    try {
      await _chatRepository.initialize();
      _addLog('✅ Repository initialized');

      // Listen to connection status
      _chatRepository.connectionStream.listen((connected) {
        _addLog(
            '🔌 Connection status: ${connected ? "Connected" : "Disconnected"}');
        setState(() {
          _isConnected = connected;
        });
        if (connected) {
          _addLog('✅ WebSocket connected successfully!');
        }
      });

      // Listen to errors
      _chatRepository.errorStream.listen((error) {
        _addLog('❌ Error: $error');
      });

      await _chatRepository.connect();
      _addLog('🔌 Connection request sent, waiting for response...');
    } catch (e) {
      _addLog('💥 Connection error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Status Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _isConnected ? Icons.wifi : Icons.wifi_off,
                    color: _isConnected ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isConnected ? 'Connected' : 'Disconnected',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isConnected
                              ? 'WebSocket is working'
                              : 'WebSocket connection failed',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Logs
          Expanded(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Debug Logs:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            log,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testConnection,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Test Connection'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _logs.clear();
                      });
                      _checkConfiguration();
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear & Retry'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _chatRepository.dispose();
    super.dispose();
  }
}
