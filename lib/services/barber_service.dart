import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class BarberService {
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
    final token = prefs.getString('token');
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ========== Schedule Management ==========

  /// Get barber's own schedules
  Future<Map<String, dynamic>> getMySchedules() async {
    try {
      final url = _getUrl('barber/schedules');
      final headers = await _getHeaders();

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get schedules: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting schedules: $e');
    }
  }

  /// Get barber's bookings
  Future<Map<String, dynamic>> getMyBookings() async {
    try {
      final url = _getUrl('barber/bookings');
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

  /// Add new time slot
  Future<Map<String, dynamic>> addTimeSlot({
    required String tanggal,
    required String jam,
  }) async {
    try {
      final url = _getUrl('barber/schedules/add');
      final headers = await _getHeaders();

      final body = {
        'tanggal': tanggal,
        'jam': jam,
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
        throw Exception(responseData['message'] ?? 'Failed to add time slot');
      }
    } catch (e) {
      throw Exception('Error adding time slot: $e');
    }
  }

  /// Delete time slot
  Future<Map<String, dynamic>> deleteTimeSlot(int scheduleId) async {
    try {
      final url = _getUrl('barber/schedules/$scheduleId');
      final headers = await _getHeaders();

      final response = await http.delete(Uri.parse(url), headers: headers);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to delete time slot');
      }
    } catch (e) {
      throw Exception('Error deleting time slot: $e');
    }
  }

  /// Get available slots for a specific date
  Future<Map<String, dynamic>> getAvailableSlots({required String tanggal}) async {
    try {
      final url = _getUrl('barber/schedules/available?tanggal=$tanggal');
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

  /// Bulk add time slots for multiple days
  Future<Map<String, dynamic>> bulkAddTimeSlots(List<Map<String, String>> slots) async {
    try {
      final url = _getUrl('barber/schedules/bulk-add');
      final headers = await _getHeaders();

      final body = {
        'slots': slots,
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
        throw Exception(responseData['message'] ?? 'Failed to bulk add time slots');
      }
    } catch (e) {
      throw Exception('Error bulk adding time slots: $e');
    }
  }

Future<Map<String, dynamic>> deleteMultipleTimeSlots(List<int> scheduleIds) async {
  try {
    final url = _getUrl('barber/jadwal/multiple-delete');
    final headers = await _getHeaders();

    final body = {
      'ids': scheduleIds,
    };

    final response = await http.delete(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );

    final responseData = json.decode(response.body);

    if (response.statusCode == 200) {
      return responseData;
    } else {
      throw Exception(responseData['message'] ?? 'Failed to delete multiple time slots');
    }
  } catch (e) {
    throw Exception('Error deleting multiple time slots: $e');
  }
}

  // ========== Statistics ==========

  /// Get barber statistics
 // Di barber_service.dart, pada method getStats
Future<Map<String, dynamic>> getStats(int barberId) async {
  try {
    final url = _getUrl('barber/stats/$barberId');
    final headers = await _getHeaders();

    final response = await http.get(Uri.parse(url), headers: headers);
    
    // Log response untuk debugging
    print('Debug - Stats API Raw Response: ${response.statusCode}, ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Pengecekan dan normalisasi data
      if (data == null) {
        return {
          'success': true,
          'stats': {
            'total_bookings_today': 0,
            'available_slots_today': 0,
            'total_bookings_this_month': 0,
            'formatted_revenue_this_month': 'Rp 0'
          }
        };
      }
      return data;
    } else {
      // Handle non-success status code
      return {
        'success': false, 
        'message': 'Failed to get stats: ${response.statusCode}',
        'stats': {
          'total_bookings_today': 0,
          'available_slots_today': 0,
          'total_bookings_this_month': 0,
          'formatted_revenue_this_month': 'Rp 0'
        }
      };
    }
  } catch (e) {
    // Mengembalikan data default jika terjadi error
    print('Debug - Error in getStats service: $e');
    return {
      'success': false,
      'message': 'Error getting stats: $e',
      'stats': {
        'total_bookings_today': 0,
        'available_slots_today': 0,
        'total_bookings_this_month': 0,
        'formatted_revenue_this_month': 'Rp 0'
      }
    };
  }
}

  // ========== Helper Methods ==========

  /// Generate time slots for a week
  List<Map<String, String>> generateWeeklySlots({
    required DateTime startDate,
    required List<String> timeSlots,
    List<int>? excludeWeekdays, // 1=Monday, 7=Sunday
  }) {
    final List<Map<String, String>> slots = [];
    excludeWeekdays ??= [];

    for (int day = 0; day < 7; day++) {
      final date = startDate.add(Duration(days: day));
      final weekday = date.weekday; // 1=Monday, 7=Sunday

      if (!excludeWeekdays.contains(weekday)) {
        for (String time in timeSlots) {
          slots.add({
            'tanggal': date.toIso8601String().split('T')[0],
            'jam': time,
          });
        }
      }
    }

    return slots;
  }

  /// Get common working hours
  static List<String> getCommonWorkingHours() {
    return [
      '08:00',
      '09:00',
      '10:00',
      '11:00',
      '13:00',
      '14:00',
      '15:00',
      '16:00',
      '17:00',
      '18:00',
      '19:00',
      '20:00',
    ];
  }

  /// Format time slot for display
  static String formatTimeSlot(String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      
      if (hour < 12) {
        return '$hour:$minute AM';
      } else if (hour == 12) {
        return '12:$minute PM';
      } else {
        return '${hour - 12}:$minute PM';
      }
    } catch (e) {
      return time; // Return original if parsing fails
    }
  }

  /// Check if time slot is in working hours
  static bool isWorkingHour(String time) {
    try {
      final hour = int.parse(time.split(':')[0]);
      return hour >= 8 && hour <= 20;
    } catch (e) {
      return false;
    }
  }
}