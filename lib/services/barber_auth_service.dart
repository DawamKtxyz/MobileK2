import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/barber_model.dart';
import '../utils/constants.dart';

class BarberAuthService {
  // Helper URL supaya baseUrl dan endpoint konsisten
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

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final url = _getUrl('barber/login');
      print('Trying to login barber at: $url');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      };

      final body = jsonEncode({
        'email': email,
        'password': password,
      });

      print('Login Headers: $headers');
      print('Login Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print('Login Response Status: ${response.statusCode}');
      print('Login Response Body: ${response.body}');

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        // Login berhasil
        if (responseBody['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', responseBody['token']);
          await prefs.setString('barber', jsonEncode(responseBody['barber']));
          await prefs.setString('user_type', 'barber');
          print('Barber login successful! Token saved.');
          
          return {
            'success': true,
            'message': responseBody['message'] ?? 'Login berhasil',
            'barber': responseBody['barber'],
          };
        }
      } else if (response.statusCode == 403) {
        // Akun belum diverifikasi
        return {
          'success': false,
          'is_verified': false,
          'message': responseBody['message'] ?? 'Akun belum diverifikasi',
          'email': responseBody['email'] ?? email,
        };
      } else if (response.statusCode == 401) {
        // Email atau password salah
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Email atau password salah',
        };
      }

      // Error lainnya
      return {
        'success': false,
        'message': responseBody['message'] ?? 'Login gagal',
      };

    } catch (e) {
      print('Login exception: $e');
      throw Exception('Login failed: $e');
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final url = _getUrl('barber/register');
      print('Registering barber at: $url');
      print('Registration data: $data');

      var request = http.MultipartRequest('POST', Uri.parse(url));

      data.forEach((key, value) {
        if (key != 'sertifikat' && value != null) {
          // Perlakukan field harga secara khusus
          if (key == 'harga') {
            // Pastikan harga dikirim sebagai string angka yang valid
            String hargaStr = value.toString().replaceAll('Rp ', '').trim();
            hargaStr = hargaStr.replaceAll('.', '');
            request.fields[key] = hargaStr;
            print('Sending harga: $hargaStr'); // Log untuk debugging
          } else {
            request.fields[key] = value.toString();
          }
        }
      });

      if (data['sertifikat'] != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'sertifikat',
            data['sertifikat'],
            filename: data['sertifikat'].split('/').last,
          ),
        );
      }

      // Debug: print semua fields yang dikirim
      print('All fields being sent: ${request.fields}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Registration Response Status: ${response.statusCode}');
      print('Registration Response Body: ${response.body}');

      final responseBody = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody['success'] == true) {
          print('Registration successful!');
          return {
            'success': true,
            'message': responseBody['message'] ?? 'Registrasi berhasil. Silakan tunggu verifikasi dari admin.',
            'barber': responseBody['barber'],
          };
        }
      }

      return {
        'success': false,
        'message': responseBody['message'] ?? 'Registrasi gagal',
        'errors': responseBody['errors'],
      };

    } catch (e) {
      print('Register exception: $e');
      throw Exception('Register failed: $e');
    }
  }

  Future<Map<String, dynamic>> checkVerificationStatus(String email) async {
    try {
      final url = _getUrl('barber/check-verification');
      print('Checking verification status at: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
        body: jsonEncode({'email': email}),
      );

      print('Verification Check Response Status: ${response.statusCode}');
      print('Verification Check Response Body: ${response.body}');

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'is_verified': responseBody['is_verified'] ?? false,
          'verified_at': responseBody['verified_at'],
          'message': responseBody['message'] ?? '',
        };
      }

      return {
        'success': false,
        'message': responseBody['message'] ?? 'Gagal memeriksa status verifikasi',
      };

    } catch (e) {
      print('Check verification exception: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('barber');
    await prefs.remove('user_type');
    print('Barber logged out and credentials cleared');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('user_type');
    final hasToken = prefs.containsKey('token');
    print('Barber isLoggedIn check: $hasToken, user_type=$userType');
    return hasToken && userType == 'barber';
  }

  Future<Barber?> getBarberProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        print('No token found for getting barber profile');
        return null;
      }

      final url = _getUrl('barber/profile');
      print('Getting barber profile from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Requested-With': 'XMLHttpRequest',
        },
      );

      print('Profile Response Status: ${response.statusCode}');
      print('Profile Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        if (responseBody['success'] == true) {
          return Barber.fromJson(responseBody['barber']);
        } else {
          print('Failed to get barber profile: ${responseBody['message'] ?? 'Unknown error'}');
          return null;
        }
      } else {
        print('Failed to get barber profile with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception getting barber profile: $e');
      throw Exception('Failed to get profile: $e');
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No token found for updating profile');
      }

      final url = _getUrl('barber/update-profile');
      print('Updating barber profile at: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Requested-With': 'XMLHttpRequest',
        },
        body: json.encode(data),
      );

      print('Update Profile Response Status: ${response.statusCode}');
      print('Update Profile Response Body: ${response.body}');

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseBody['success'] == true) {
          // Update local storage with new barber data
          await prefs.setString('barber', json.encode(responseBody['barber']));
          print('Profile updated successfully!');
          return responseBody;
        } else {
          throw Exception(responseBody['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception(responseBody['message'] ?? 'Update failed with status ${response.statusCode}');
      }
    } catch (e) {
      print('Update profile exception: $e');
      throw Exception('Update profile failed: $e');
    }
  }

  Future<Barber?> getCurrentBarber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final barberJson = prefs.getString('barber');
      
      if (barberJson != null) {
        final barberData = json.decode(barberJson);
        return Barber.fromJson(barberData);
      }
      
      return null;
    } catch (e) {
      print('Error getting current barber: $e');
      return null;
    }
  }
}