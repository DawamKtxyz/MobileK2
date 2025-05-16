import 'package:shared_preferences/shared_preferences.dart';
import 'barber_auth_service.dart';
import 'pelanggan_auth_service.dart';

enum UserType {
  barber,
  pelanggan
}

class AuthServiceFactory {
  static final BarberAuthService _barberAuthService = BarberAuthService();
  static final PelangganAuthService _pelangganAuthService = PelangganAuthService();

  // Get auth service based on user type
  static dynamic getAuthService(UserType userType) {
    switch (userType) {
      case UserType.barber:
        return _barberAuthService;
      case UserType.pelanggan:
        return _pelangganAuthService;
      default:
        throw Exception('Invalid user type');
    }
  }

  // Check if any user is logged in
  static Future<bool> isLoggedIn() async {
    final barberLoggedIn = await _barberAuthService.isLoggedIn();
    final pelangganLoggedIn = await _pelangganAuthService.isLoggedIn();
    
    return barberLoggedIn || pelangganLoggedIn;
  }

  // Get current user type
  static Future<UserType?> getCurrentUserType() async {
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('user_type');
    
    if (userType == 'barber') return UserType.barber;
    if (userType == 'pelanggan') return UserType.pelanggan;
    
    return null;
  }

  // Logout current user
  static Future<void> logout() async {
    final userType = await getCurrentUserType();
    
    if (userType == UserType.barber) {
      await _barberAuthService.logout();
    } else if (userType == UserType.pelanggan) {
      await _pelangganAuthService.logout();
    }
  }
}