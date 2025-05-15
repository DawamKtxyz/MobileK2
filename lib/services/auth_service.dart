import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/barber_model.dart';
import '../utils/constants.dart';

class AuthService {
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/api/barber/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final responseBody = json.decode(response.body);

      if (responseBody['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', responseBody['token']);
        await prefs.setString('barber', jsonEncode(responseBody['barber']));
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    try {
      // Buat request multipart
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('${Constants.baseUrl}/api/barber/register')
      );

      // Tambahkan field-field text
      data.forEach((key, value) {
        if (key != 'sertifikat' && value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Tambahkan file sertifikat
      if (data['sertifikat'] != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'sertifikat', 
            data['sertifikat'],
            filename: data['sertifikat'].split('/').last
          )
        );
      }

      // Kirim request
      final streamedResponse = await request.send();
      
      // Konversi stream response ke response biasa
      final response = await http.Response.fromStream(streamedResponse);

      // Decode response body
      final responseBody = json.decode(response.body);

      // Cek status response
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        // Tampilkan pesan error dari server
        throw Exception(responseBody['message'] ?? 'Registrasi gagal');
      }
    } catch (e) {
      throw Exception('Register failed: $e');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('barber');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('token');
  }

  Future<Barber?> getBarberProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return null;

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/api/barber/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = json.decode(response.body);

      if (responseBody['success'] == true) {
        return Barber.fromJson(responseBody['barber']);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }
}