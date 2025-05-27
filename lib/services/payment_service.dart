// File: services/payment_service.dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';

class PaymentService {
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

  /// Create payment for booking
  Future<Map<String, dynamic>> createPayment(int bookingId) async {
    try {
      final url = _getUrl('payment/create/$bookingId');
      final headers = await _getHeaders();

      final response = await http.post(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create payment');
      }
    } catch (e) {
      throw Exception('Error creating payment: $e');
    }
  }

  /// Check payment status
  Future<Map<String, dynamic>> checkPaymentStatus(String orderId) async {
    try {
      final url = _getUrl('payment/status/$orderId');
      final headers = await _getHeaders();

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to check payment status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error checking payment status: $e');
    }
  }

  /// Get payment history
  Future<Map<String, dynamic>> getPaymentHistory() async {
    try {
      final url = _getUrl('payment/history');
      final headers = await _getHeaders();

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get payment history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting payment history: $e');
    }
  }

  /// Launch payment URL in browser
  Future<bool> launchPaymentUrl(String paymentUrl) async {
    try {
      final uri = Uri.parse(paymentUrl);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
      return false;
    } catch (e) {
      print('Error launching payment URL: $e');
      return false;
    }
  }

  /// Format payment status for display
  static String getPaymentStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'paid':
      case 'settlement':
        return 'Berhasil';
      case 'failed':
      case 'deny':
        return 'Gagal';
      case 'expired':
      case 'expire':
        return 'Kedaluwarsa';
      case 'cancel':
        return 'Dibatalkan';
      default:
        return 'Tidak Diketahui';
    }
  }

  /// Get payment status color
  static Color getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'paid':
      case 'settlement':
        return Colors.green;
      case 'failed':
      case 'deny':
        return Colors.red;
      case 'expired':
      case 'expire':
        return Colors.grey;
      case 'cancel':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// File: models/payment_model.dart
class Payment {
  final int id;
  final String orderId;
  final String barberName;
  final double serviceFee;
  final double deliveryFee;
  final double totalAmount;
  final String paymentStatus;
  final String? paymentMethod;
  final DateTime? paidAt;
  final String bookingDate;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.orderId,
    required this.barberName,
    required this.serviceFee,
    required this.deliveryFee,
    required this.totalAmount,
    required this.paymentStatus,
    this.paymentMethod,
    this.paidAt,
    required this.bookingDate,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      orderId: json['order_id'],
      barberName: json['barber_name'],
      serviceFee: json['service_fee'].toDouble(),
      deliveryFee: json['delivery_fee'].toDouble(),
      totalAmount: json['total_amount'].toDouble(),
      paymentStatus: json['payment_status'],
      paymentMethod: json['payment_method'],
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      bookingDate: json['booking_date'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get formattedTotalAmount {
    return 'Rp ${totalAmount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  String get statusText => PaymentService.getPaymentStatusText(paymentStatus);
  Color get statusColor => PaymentService.getPaymentStatusColor(paymentStatus);
}