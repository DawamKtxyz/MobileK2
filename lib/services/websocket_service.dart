// File: services/websocket_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class WebSocketService {
  WebSocket? _socket;
  bool _isConnected = false;
  Function(Map<String, dynamic>)? _messageHandler;
  Function(Map<String, dynamic>)? _typingHandler;
  Function()? _connectionHandler;
  Function()? _disconnectionHandler;
  
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  bool get isConnected => _isConnected;

  // Set message handler
  void setMessageHandler(Function(Map<String, dynamic>) handler) {
    _messageHandler = handler;
  }

  // Set typing handler
  void setTypingHandler(Function(Map<String, dynamic>) handler) {
    _typingHandler = handler;
  }

  // Set connection handlers
  void setConnectionHandlers({
    Function()? onConnect,
    Function()? onDisconnect,
  }) {
    _connectionHandler = onConnect;
    _disconnectionHandler = onDisconnect;
  }

  // Connect to WebSocket server
  Future<void> connect() async {
    if (_isConnected) return;

    try {
      final token = await _getToken();
      final currentUser = await _getCurrentUser();
      
      if (token == null || currentUser == null) {
        print('Cannot connect to WebSocket: Missing token or user data');
        return;
      }

      // Build WebSocket URL
      String wsUrl = Constants.baseUrl.replaceAll('http://', 'ws://').replaceAll('https://', 'wss://');
      wsUrl = wsUrl.replaceAll('/api', '');
      wsUrl = '$wsUrl/ws/chat?token=$token&user_id=${currentUser['data']['id']}&user_type=${currentUser['type']}';

      print('Connecting to WebSocket: $wsUrl');

      _socket = await WebSocket.connect(wsUrl);
      _isConnected = true;
      
      print('WebSocket connected successfully');
      _connectionHandler?.call();

      // Listen for messages
      _socket!.listen(
        (data) {
          try {
            final message = json.decode(data);
            _handleMessage(message);
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _handleDisconnection();
        },
        onDone: () {
          print('WebSocket connection closed');
          _handleDisconnection();
        },
      );

      // Send initial connection message
      _sendMessage({
        'type': 'connection',
        'user_id': currentUser['data']['id'],
        'user_type': currentUser['type'],
      });

    } catch (e) {
      print('Failed to connect to WebSocket: $e');
      _handleDisconnection();
    }
  }

  // Disconnect from WebSocket
  void disconnect() {
    if (_socket != null) {
      _socket!.close();
      _socket = null;
    }
    _handleDisconnection();
  }

  // Send message through WebSocket
  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _socket != null) {
      _sendMessage(message);
    } else {
      print('Cannot send message: WebSocket not connected');
    }
  }

  // Send typing indicator
  void sendTypingIndicator(int chatId, bool isTyping) {
    if (_isConnected && _socket != null) {
      _sendMessage({
        'type': 'typing',
        'chat_id': chatId,
        'is_typing': isTyping,
      });
    }
  }

  // Join chat room
  void joinChat(int chatId) {
    if (_isConnected && _socket != null) {
      _sendMessage({
        'type': 'join_chat',
        'chat_id': chatId,
      });
    }
  }

  // Leave chat room
  void leaveChat(int chatId) {
    if (_isConnected && _socket != null) {
      _sendMessage({
        'type': 'leave_chat',
        'chat_id': chatId,
      });
    }
  }

  // Private methods
  void _sendMessage(Map<String, dynamic> message) {
    try {
      final jsonMessage = json.encode(message);
      _socket!.add(jsonMessage);
    } catch (e) {
      print('Error sending WebSocket message: $e');
    }
  }

  void _handleMessage(Map<String, dynamic> message) {
    final type = message['type'];
    
    switch (type) {
      case 'new_message':
        _messageHandler?.call(message['data']);
        break;
      case 'message_read':
        _messageHandler?.call(message['data']);
        break;
      case 'typing':
        _typingHandler?.call(message['data']);
        break;
      case 'user_online':
      case 'user_offline':
        // Handle user presence updates
        _messageHandler?.call(message['data']);
        break;
      case 'chat_updated':
        _messageHandler?.call(message['data']);
        break;
      case 'error':
        print('WebSocket error: ${message['message']}');
        break;
      default:
        print('Unknown WebSocket message type: $type');
    }
  }

  void _handleDisconnection() {
    _isConnected = false;
    _socket = null;
    _disconnectionHandler?.call();
    
    // Try to reconnect after a delay
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isConnected) {
        print('Attempting to reconnect WebSocket...');
        connect();
      }
    });
  }

  // Helper methods
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>?> _getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userTypeString = prefs.getString('user_type');
    
    if (userTypeString == 'barber') {
      final barberJson = prefs.getString('barber');
      if (barberJson != null) {
        return {
          'type': 'barber',
          'data': json.decode(barberJson),
        };
      }
    } else if (userTypeString == 'pelanggan') {
      final pelangganJson = prefs.getString('pelanggan');
      if (pelangganJson != null) {
        return {
          'type': 'pelanggan',
          'data': json.decode(pelangganJson),
        };
      }
    }
    
    return null;
  }

  // Clean up resources
  void dispose() {
    disconnect();
    _messageHandler = null;
    _typingHandler = null;
    _connectionHandler = null;
    _disconnectionHandler = null;
  }
}