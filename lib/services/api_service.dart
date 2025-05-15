// api_services.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {
  Uri _buildUri(String endpoint) {
    // Jika endpoint sudah berupa URL lengkap, gunakan langsung
    if (endpoint.startsWith('http')) {
      return Uri.parse(endpoint);
    }
    // Jika tidak, gabungkan dengan baseUrl
    return Uri.parse('${Constants.baseUrl}$endpoint');
  }

Future<Map<String, dynamic>> registerWithFile({
    required String nama,
    required String email,
    required String password,
    required String telepon,
    String? spesialisasi,
    required File sertifikat,
  }) async {
    try {
      // Buat request multipart
      var request = http.MultipartRequest(
        'POST', 
        _buildUri('/api/barber/register')
      );

      // Tambahkan field-field text
      request.fields['nama'] = nama;
      request.fields['email'] = email;
      request.fields['password'] = password;
      request.fields['telepon'] = telepon;
      
      // Tambahkan spesialisasi jika ada
      if (spesialisasi != null && spesialisasi.isNotEmpty) {
        request.fields['spesialisasi'] = spesialisasi;
      }

      // Tambahkan file sertifikat
      request.files.add(
        await http.MultipartFile.fromPath(
          'sertifikat', 
          sertifikat.path,
          filename: sertifikat.path.split('/').last
        )
      );

      // Kirim request
      final streamedResponse = await request.send();
      
      // Konversi stream response ke response biasa
      final response = await http.Response.fromStream(streamedResponse);

      // Cetak response untuk debugging
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // Decode response body
      final responseBody = json.decode(response.body);

      // Cek status response
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Registrasi berhasil'
        };
      } else {
        // Tampilkan pesan error dari server
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Registrasi gagal'
        };
      }
    } catch (e) {
      print('Error pada register: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }

Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body, {String? token}) async {
  try {
    final response = await http.post(
      _buildUri(endpoint),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    throw Exception('Error: $e');
  }
}

Future<Map<String, dynamic>> postWithFile(String endpoint, Map<String, dynamic> body, String fileKey, String filePath) async {
    try {
      // Buat request multipart
      var request = http.MultipartRequest('POST', _buildUri(endpoint));

      // Tambahkan field-field text
      body.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Tambahkan file
      request.files.add(await http.MultipartFile.fromPath(
        fileKey, 
        filePath,
      ));

      // Kirim request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to upload file: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading file: $e');
    }
  }

  Future<Map<String, dynamic>> get(String endpoint, String token) async {
    try {
      final response = await http.get(
        _buildUri(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
