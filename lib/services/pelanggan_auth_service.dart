import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pelanggan_model.dart';
import '../utils/constants.dart';

class PelangganAuthService {
  // URL helper untuk menghindari duplikasi /api/
  String _getUrl(String endpoint) {
    // Hapus slash di awal endpoint jika ada
    if (endpoint.startsWith('/')) {
      endpoint = endpoint.substring(1);
    }
    
    // Jika baseUrl sudah mengandung /api, pastikan endpoint tidak mengandung /api lagi
    if (Constants.baseUrl.endsWith('/api')) {
      return '${Constants.baseUrl}/$endpoint';
    } else {
      return '${Constants.baseUrl}/api/$endpoint';
    }
  }

  // Test CORS
  Future<bool> testCors() async {
    try {
      final url = _getUrl('cors-test');
      print('Testing CORS at: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        },
      );
      
      print('CORS Test Status: ${response.statusCode}');
      print('CORS Test Headers: ${response.headers}');
      print('CORS Test Body: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          return data['success'] == true;
        } catch (e) {
          print('Error parsing CORS test response: $e');
          return false;
        }
      }
      return false;
    } catch (e) {
      print('CORS test failed with error: $e');
      return false;
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    try {
      final url = _getUrl('pelanggan/login');
      print('Trying to login at: $url');
      
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      };
      
      final Map<String, dynamic> body = {
        'email': email,
        'password': password,
      };
      
      print('Login Headers: $headers');
      print('Login Body: $body');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      
      print('Login Response Status: ${response.statusCode}');
      print('Login Response Headers: ${response.headers}');
      
      // Truncate response body for logging if it's too long
      final bodyPreview = response.body.length > 500 
          ? '${response.body.substring(0, 500)}...' 
          : response.body;
      print('Login Response Body (preview): $bodyPreview');
      
      // Check if the response is a redirect
      if (response.statusCode >= 300 && response.statusCode < 400) {
        print('Redirect detected to: ${response.headers['location']}');
        throw Exception('Server redirected the request. This might indicate an authentication issue or incorrect URL.');
      }
      
      // Check if response is successful
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final responseBody = json.decode(response.body);
          
          if (responseBody['success'] == true) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('pelanggan_token', responseBody['token']);
            await prefs.setString('pelanggan', jsonEncode(responseBody['pelanggan']));
            await prefs.setString('user_type', 'pelanggan');
            print('Login successful! Token saved.');
            return true;
          } else {
            print('Login failed: ${responseBody['message'] ?? 'Unknown error'}');
            return false;
          }
        } catch (e) {
          print('Error decoding JSON: $e');
          
          if (response.body.contains('<!DOCTYPE html>')) {
            print('HTML detected in response instead of JSON');
            throw Exception('Server returned HTML instead of JSON. This might be due to CORS issues or a server error.');
          }
          
          throw Exception('Failed to decode server response: $e');
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        
        if (response.body.contains('<!DOCTYPE html>')) {
          throw Exception('Server returned HTML with status ${response.statusCode}. Check server logs for more information.');
        }
        
        try {
          final errorBody = json.decode(response.body);
          throw Exception(errorBody['message'] ?? 'Login failed with status ${response.statusCode}');
        } catch (e) {
          throw Exception('Login failed with status ${response.statusCode}. Server response could not be parsed.');
        }
      }
    } catch (e) {
      print('Login exception: $e');
      throw Exception('Login failed: $e');
    }
  }

  // Register
  Future<bool> register(Map<String, dynamic> data) async {
    try {
      final url = _getUrl('pelanggan/register');
      print('Registering at: $url');
      print('Registration data: $data');
      
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      };
      
      print('Registration Headers: $headers');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(data),
      );
      
      print('Registration Response Status: ${response.statusCode}');
      print('Registration Response Headers: ${response.headers}');
      
      // Truncate response body for logging if it's too long
      final bodyPreview = response.body.length > 500 
          ? '${response.body.substring(0, 500)}...' 
          : response.body;
      print('Registration Response Body (preview): $bodyPreview');
      
      // Check if response is successful
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final responseBody = json.decode(response.body);
          
          if (responseBody['success'] == true) {
            print('Registration successful!');
            return true;
          } else {
            print('Registration failed: ${responseBody['message'] ?? 'Unknown error'}');
            return false;
          }
        } catch (e) {
          print('Error decoding JSON: $e');
          
          if (response.body.contains('<!DOCTYPE html>')) {
            print('HTML detected in response instead of JSON');
            throw Exception('Server returned HTML instead of JSON. This might be due to CORS issues or a server error.');
          }
          
          throw Exception('Failed to decode server response: $e');
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        
        if (response.body.contains('<!DOCTYPE html>')) {
          throw Exception('Server returned HTML with status ${response.statusCode}. Check server logs for more information.');
        }
        
        try {
          final errorBody = json.decode(response.body);
          throw Exception(errorBody['message'] ?? 'Registration failed with status ${response.statusCode}');
        } catch (e) {
          throw Exception('Registration failed with status ${response.statusCode}. Server response could not be parsed.');
        }
      }
    } catch (e) {
      print('Registration exception: $e');
      throw Exception('Registration failed: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('pelanggan_token');
      
      if (token != null) {
        final url = _getUrl('pelanggan/logout');
        print('Logging out at: $url');
        
        try {
          final response = await http.post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
              'X-Requested-With': 'XMLHttpRequest'
            },
          );
          
          print('Logout Response Status: ${response.statusCode}');
        } catch (e) {
          // Continue with local logout even if API call fails
          print('Logout API call failed: $e');
        }
      }
      
      // Clear local storage regardless of API call result
      await prefs.remove('pelanggan_token');
      await prefs.remove('pelanggan');
      await prefs.remove('user_type');
      print('Local logout completed - all credentials cleared');
    } catch (e) {
      print('Logout exception: $e');
      // Still try to clear preferences even if there was an error
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('pelanggan_token');
        await prefs.remove('pelanggan');
        await prefs.remove('user_type');
      } catch (_) {}
      
      throw Exception('Logout error: $e');
    }
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString('user_type');
      final hasToken = prefs.containsKey('pelanggan_token');
      
      print('Checking login status - User type: $userType, Has token: $hasToken');
      
      return hasToken && userType == 'pelanggan';
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Get profile
  Future<Pelanggan?> getPelangganProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('pelanggan_token');
      
      if (token == null) {
        print('Cannot get profile: No auth token found');
        return null;
      }
      
      final url = _getUrl('pelanggan/profile');
      print('Getting profile from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Requested-With': 'XMLHttpRequest'
        },
      );
      
      print('Profile Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        try {
          final responseBody = json.decode(response.body);
          
          if (responseBody['success'] == true) {
            print('Profile retrieved successfully');
            return Pelanggan.fromJson(responseBody['pelanggan']);
          } else {
            print('Failed to get profile: ${responseBody['message'] ?? 'Unknown error'}');
            return null;
          }
        } catch (e) {
          print('Error decoding profile response: $e');
          return null;
        }
      } else {
        print('Failed to get profile with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception getting profile: $e');
      throw Exception('Failed to get profile: $e');
    }
  }
}