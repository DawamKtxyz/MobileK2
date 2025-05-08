import 'dart:convert'; // Tambahkan import ini
import 'package:shared_preferences/shared_preferences.dart';
import '../models/barber_model.dart';
import 'api_service.dart';
import '../utils/constants.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiService.post(Constants.loginEndpoint, {
        'email': email,
        'password': password,
      });

      if (response['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response['token']);
        await prefs.setString('barber', jsonEncode(response['barber']));
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(Constants.registerEndpoint, data);
      return response['success'] == true;
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

      final response = await _apiService.get(Constants.profileEndpoint, token);

      if (response['success'] == true) {
        return Barber.fromJson(response['barber']);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }
}