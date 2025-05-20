import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class PelangganService {
  // Helper URL untuk konsistensi
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

  // Get authorization headers
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('pelanggan_token');
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ========== Barber Discovery ==========

  /// Search barbers with filters
  Future<Map<String, dynamic>> searchBarbers({
    String? search,
    String? spesialisasi,
    double? hargaMin,
    double? hargaMax,
    String sortBy = 'nama',
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      // Build query parameters
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
        'sort_by': sortBy,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (spesialisasi != null && spesialisasi.isNotEmpty) {
        queryParams['spesialisasi'] = spesialisasi;
      }
      if (hargaMin != null) {
        queryParams['harga_min'] = hargaMin.toString();
      }
      if (hargaMax != null) {
        queryParams['harga_max'] = hargaMax.toString();
      }

      final queryString = queryParams.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      // Use public route for barber search
      final url = _getUrl('public/barbers?$queryString');
      final headers = await _getHeaders();

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to search barbers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching barbers: $e');
    }
  }

  /// Get barber details
  Future<Map<String, dynamic>> getBarberDetails(int barberId) async {
    try {
      // Use public route for barber details
      final url = _getUrl('public/barbers/$barberId');
      final headers = await _getHeaders();

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get barber details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting barber details: $e');
    }
  }

  /// Get available slots for a barber on a specific date
  Future<Map<String, dynamic>> getBarberAvailableSlots({
    required int barberId,
    required String date,
  }) async {
    try {
      // Use public route for available slots
      final url = _getUrl('public/barbers/$barberId/slots?date=$date');
      final headers = await _getHeaders();

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get available slots: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting available slots: $e');
    }
  }

  /// Get popular specializations
  Future<Map<String, dynamic>> getSpecializations() async {
    try {
      // Use public route for specializations
      final url = _getUrl('public/specializations');
      final headers = await _getHeaders();

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get specializations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting specializations: $e');
    }
  }

  // ========== Booking Management ==========

  /// Create a new booking
  Future<Map<String, dynamic>> createBooking({
    required int barberId,
    required int jadwalId,
    required String alamatLengkap,
    required String email,
    required String telepon,
    double? ongkosKirim,
  }) async {
    try {
      final url = _getUrl('pelanggan/bookings');
      final headers = await _getHeaders();

      final body = {
        'id_barber': barberId,
        'jadwal_id': jadwalId,
        'alamat_lengkap': alamatLengkap,
        'email': email,
        'telepon': telepon,
        if (ongkosKirim != null) 'ongkos_kirim': ongkosKirim,
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
        throw Exception(responseData['message'] ?? 'Failed to create booking');
      }
    } catch (e) {
      throw Exception('Error creating booking: $e');
    }
  }

  /// Get customer's bookings
  Future<Map<String, dynamic>> getMyBookings({String status = 'all'}) async {
    try {
      final url = _getUrl('pelanggan/bookings?status=$status');
      final headers = await _getHeaders();

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get bookings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting bookings: $e');
    }
  }

  /// Get booking details
  Future<Map<String, dynamic>> getBookingDetails(int bookingId) async {
    try {
      final url = _getUrl('pelanggan/bookings/$bookingId');
      final headers = await _getHeaders();

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get booking details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting booking details: $e');
    }
  }

  /// Cancel a booking
  Future<Map<String, dynamic>> cancelBooking(int bookingId) async {
    try {
      final url = _getUrl('pelanggan/bookings/$bookingId');
      final headers = await _getHeaders();

      final response = await http.delete(Uri.parse(url), headers: headers);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to cancel booking');
      }
    } catch (e) {
      throw Exception('Error cancelling booking: $e');
    }
  }

  /// Get booking statistics
  Future<Map<String, dynamic>> getBookingStats() async {
    try {
      final url = _getUrl('pelanggan/bookings-stats');
      final headers = await _getHeaders();

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get booking stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting booking stats: $e');
    }
  }

  // ========== Helper Methods ==========

  /// Format price to Indonesian Rupiah
  static String formatPrice(dynamic price) {
    try {
      final double priceValue = price is String 
          ? double.parse(price) 
          : price.toDouble();
      
      return 'Rp ${priceValue.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      )}';
    } catch (e) {
      return 'Rp 0';
    }
  }

  /// Parse price from formatted string
  static double parsePrice(String formattedPrice) {
    try {
      return double.parse(
        formattedPrice
            .replaceAll('Rp', '')
            .replaceAll('.', '')
            .replaceAll(',', '')
            .trim()
      );
    } catch (e) {
      return 0.0;
    }
  }

  /// Get available booking dates (next 7 days)
  static List<Map<String, dynamic>> getAvailableDates({int dayCount = 7}) {
    final List<Map<String, dynamic>> dates = [];
    final now = DateTime.now();

    for (int i = 0; i < dayCount; i++) {
      final date = now.add(Duration(days: i));
      dates.add({
        'date': date.toIso8601String().split('T')[0],
        'day_name': _getDayName(date.weekday),
        'day_short': _getDayShort(date.weekday),
        'day_number': date.day.toString(),
        'is_today': i == 0,
        'is_tomorrow': i == 1,
        'formatted': '${date.day} ${_getMonthName(date.month)} ${date.year}',
      });
    }

    return dates;
  }

  static String _getDayName(int weekday) {
    const days = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    return days[weekday - 1];
  }

  static String _getDayShort(int weekday) {
    const days = [
      'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'
    ];
    return days[weekday - 1];
  }

  static String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }

  /// Check if a booking can be cancelled
  static bool canCancelBooking(DateTime scheduleDateTime) {
    final now = DateTime.now();
    final hoursDifference = scheduleDateTime.difference(now).inHours;
    return hoursDifference > 2 && scheduleDateTime.isAfter(now);
  }

  /// Get booking status
  static String getBookingStatus(DateTime scheduleDateTime) {
    final now = DateTime.now();
    if (scheduleDateTime.isBefore(now)) {
      return 'completed';
    } else {
      return 'upcoming';
    }
  }

  /// Get time until appointment
  static String getTimeUntilAppointment(DateTime scheduleDateTime) {
    final now = DateTime.now();
    final difference = scheduleDateTime.difference(now);

    if (difference.isNegative) {
      return 'Selesai';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays} hari lagi';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lagi';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lagi';
    } else {
      return 'Sebentar lagi';
    }
  }
}