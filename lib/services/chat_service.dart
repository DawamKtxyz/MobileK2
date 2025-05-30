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
      
      print('Debug - Chats response status: ${response.statusCode}');
      print('Debug - Chats response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get chats: ${response.statusCode}');
      }
    } catch (e) {
      print('Debug - Error in getChats: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get chat list - this is used by ChatListScreen
  Future<Map<String, dynamic>> getChatList() async {
    try {
      // This uses the same API endpoint as getChats
      final result = await getChats();
      
      // Check if the result has the expected format
      if (result['success'] == true) {
        // If API returns chats directly, format them for the chat list screen
        return {
          'success': true,
          'data': result['chats'] ?? [] // Ensure we have a list, even if empty
        };
      } else {
        // If there was an error, propagate it
        return result;
      }
    } catch (e) {
      print('Debug - Error in getChatList: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get or create direct chat with barber (NEW - untuk chat sebelum booking)
  Future<Map<String, dynamic>> getOrCreateDirectChat(int userId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('user_type');
    
    final url = _getUrl('chats/direct');
    final headers = await _getHeaders();

    // Determine the correct parameter name based on user type
    final String paramName = userType == 'barber' ? 'pelanggan_id' : 'barber_id';
    
    final body = {
      paramName: userId,
    };

    print('Debug - Sending direct chat request to: $url');
    print('Debug - Request body: ${json.encode(body)}');
    print('Debug - User type: $userType');

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );

    print('Debug - Direct chat response status: ${response.statusCode}');
    print('Debug - Direct chat response body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get/create direct chat: ${response.statusCode}');
    }
  } catch (e) {
    print('Debug - Error in getOrCreateDirectChat: $e');
    return {'success': false, 'message': e.toString()};
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
      print('Debug - Error in getChatById: $e');
      return {'success': false, 'message': e.toString()};
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

      print('Debug - Sending message to: $url');
      print('Debug - Message body: ${json.encode(body)}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      );

      print('Debug - Send message response status: ${response.statusCode}');
      print('Debug - Send message response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to send message');
      }
    } catch (e) {
      print('Debug - Error in sendMessage: $e');
      return {'success': false, 'message': e.toString()};
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
      print('Debug - Error in getChatByBooking: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}