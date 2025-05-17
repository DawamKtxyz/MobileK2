import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Ganti dengan url API kamu (pastikan tanpa slash di akhir)
  final String baseUrl = 'http://127.0.0.1:8000/api';

   Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

 Future<bool> register(Map<String, dynamic> data, {PlatformFile? file}) async {
  try {
    var uri = Uri.parse('$baseUrl/barber/register');
    var request = http.MultipartRequest('POST', uri);

    // Tambahkan fields dari data
    data.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        // Pastikan harga dikirim sebagai string yang valid
        if (key == 'harga') {
          // Hapus karakter 'Rp ' jika ada
          String hargaStr = value.toString().replaceAll('Rp ', '').trim();
          // Hapus semua titik sebagai pemisah ribuan jika ada
          hargaStr = hargaStr.replaceAll('.', '');
          request.fields[key] = hargaStr;
          print('Sending harga: $hargaStr'); // Log untuk debugging
        } else {
          request.fields[key] = value.toString();
        }
      }
    });

    // Tambahkan file sertifikat jika ada
    if (file != null) {
      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          'sertifikat',
          file.bytes!,
          filename: file.name,
          contentType: MediaType('application', 'pdf'),
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'sertifikat',
          file.path!,
          contentType: MediaType('application', 'pdf'),
        ));
      }
    }

    // Debug: print semua fields yang dikirim
    print('Sending data to server: ${request.fields}');

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    
    // Debug: print response body
    print('Register Response Status: ${response.statusCode}');
    print('Register Response Body: ${response.body}');

    if (streamedResponse.statusCode == 201 || streamedResponse.statusCode == 200) {
      return true;
    } else {
      print('Register failed with status: ${streamedResponse.statusCode}');
      return false;
    }
  } catch (e) {
    print('Exception in register: $e');
    return false;
  }
}
}
