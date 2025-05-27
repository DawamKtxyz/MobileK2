// File: services/simple_chat_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class SimpleChatService {
  Timer? _pollingTimer;
  Function(Map<String, dynamic>)? onNewMessage;
  
  String _getUrl(String endpoint) {
    if (endpoint.startsWith('/')) {
      endpoint = endpoint.substring(1);
    }
    if (Constants.baseUrl.endsWith('/api')) {
      return '${Constants.baseUrl}/$endpoint';
    } else {
      return '${Constants.baseUrl}/api/$endpoint';
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('user_type');
    final token = userType == 'barber' 
        ? prefs.getString('token')
        : prefs.getString('pelanggan_token');
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Start polling for new messages (alternatif WebSocket)
  void startPolling({required int chatId, Duration interval = const Duration(seconds: 3)}) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (timer) async {
      try {
        await _checkForNewMessages(chatId);
      } catch (e) {
        print('Polling error: $e');
      }
    });
  }

  /// Stop polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Check for new messages
  Future<void> _checkForNewMessages(int chatId) async {
    try {
      final url = _getUrl('chats/booking/$chatId');
      final headers = await _getHeaders();

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && onNewMessage != null) {
          onNewMessage!(data);
        }
      }
    } catch (e) {
      print('Error checking messages: $e');
    }
  }

  /// Set message handler
  void setMessageHandler(Function(Map<String, dynamic>) handler) {
    onNewMessage = handler;
  }

  /// Get all chats for current user
  Future<Map<String, dynamic>> getChats() async {
    try {
      final url = _getUrl('chats');
      final headers = await _getHeaders();

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get chats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting chats: $e');
    }
  }

  /// Get chat by booking ID
  Future<Map<String, dynamic>> getChatByBooking(int bookingId) async {
    try {
      final url = _getUrl('chats/booking/$bookingId');
      final headers = await _getHeaders();

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get chat: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting chat: $e');
    }
  }

  /// Send message
  Future<Map<String, dynamic>> sendMessage({
    required int chatId,
    required String message,
    String messageType = 'text',
  }) async {
    try {
      final url = _getUrl('chats/send');
      final headers = await _getHeaders();

      final body = {
        'chat_id': chatId,
        'message': message,
        'message_type': messageType,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to send message');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  void dispose() {
    stopPolling();
  }
}