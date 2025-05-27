import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ChatService {
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

  /// Get or create direct chat with barber (NEW - untuk chat sebelum booking)
  Future<Map<String, dynamic>> getOrCreateDirectChat(int barberId) async {
    try {
      final url = _getUrl('chats/direct');
      final headers = await _getHeaders();

      final body = {
        'barber_id': barberId,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get/create direct chat: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting/creating direct chat: $e');
    }
  }

  /// Get chat by chat ID
  Future<Map<String, dynamic>> getChatById(int chatId) async {
    try {
      final url = _getUrl('chats/$chatId');
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

  /// Legacy method - get chat by booking ID (untuk backward compatibility)
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

  getChatList() {}
}