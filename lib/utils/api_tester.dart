import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiTester {
  /// Tests the API connection
  static Future<bool> testApiConnection() async {
    try {
      print('Testing API connection to: ${Constants.baseUrl}/api/test');
      
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/api/test'),
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        },
      );
      
      print('API test response status: ${response.statusCode}');
      print('API test response body: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          print('API connection successful: ${data['message']}');
          return data['success'] == true;
        } catch (e) {
          print('Error decoding JSON response: $e');
          return false;
        }
      }
      
      return false;
    } catch (e) {
      print('API test failed: $e');
      return false;
    }
  }
  
  /// Tests a POST request to the API
  static Future<Map<String, dynamic>> testPostRequest(String endpoint, Map<String, dynamic> data) async {
    try {
      print('Testing POST request to: ${Constants.baseUrl}$endpoint');
      print('Request data: $data');
      
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        },
        body: json.encode(data),
      );
      
      print('POST test response status: ${response.statusCode}');
      print('POST test response headers: ${response.headers}');
      print('POST test response body: ${response.body}');
      
      try {
        return {
          'success': response.statusCode >= 200 && response.statusCode < 300,
          'statusCode': response.statusCode,
          'body': json.decode(response.body),
          'isJson': true,
        };
      } catch (e) {
        print('Error decoding JSON response: $e');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'body': response.body,
          'isJson': false,
          'error': e.toString(),
        };
      }
    } catch (e) {
      print('POST request test failed: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}