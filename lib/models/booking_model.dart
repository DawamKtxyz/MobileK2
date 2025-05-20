class Booking {
  final int id;
  final String idTransaksi;
  final BarberInfo barber;
  final ScheduleInfo schedule;
  final BookingDetails bookingDetails;
  final String status;
  final bool canCancel;
  final DateTime createdAt;
  final String? timeUntilAppointment;

  Booking({
    required this.id,
    required this.idTransaksi,
    required this.barber,
    required this.schedule,
    required this.bookingDetails,
    required this.status,
    required this.canCancel,
    required this.createdAt,
    this.timeUntilAppointment,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      idTransaksi: json['id_transaksi'],
      barber: BarberInfo.fromJson(json['barber']),
      schedule: ScheduleInfo.fromJson(json['schedule']),
      bookingDetails: BookingDetails.fromJson(json['booking_details'] ?? json['booking_info'] ?? {}),
      status: json['status'] ?? 'pending',
      canCancel: json['can_cancel'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      timeUntilAppointment: json['time_until_appointment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_transaksi': idTransaksi,
      'barber': barber.toJson(),
      'schedule': schedule.toJson(),
      'booking_details': bookingDetails.toJson(),
      'status': status,
      'can_cancel': canCancel,
      'created_at': createdAt.toIso8601String(),
      'time_until_appointment': timeUntilAppointment,
    };
  }
}

class BarberInfo {
  final int id;
  final String nama;
  final String? spesialisasi;
  final String? telepon;
  final String? email;

  BarberInfo({
    required this.id,
    required this.nama,
    this.spesialisasi,
    this.telepon,
    this.email,
  });

  factory BarberInfo.fromJson(Map<String, dynamic> json) {
    return BarberInfo(
      id: json['id'],
      nama: json['nama'],
      spesialisasi: json['spesialisasi'],
      telepon: json['telepon'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'spesialisasi': spesialisasi,
      'telepon': telepon,
      'email': email,
    };
  }
}

class ScheduleInfo {
  final String date;
  final String time;
  final String? dayName;
  final String? formattedDate;
  final String? formattedDatetime;

  ScheduleInfo({
    required this.date,
    required this.time,
    this.dayName,
    this.formattedDate,
    this.formattedDatetime,
  });

  factory ScheduleInfo.fromJson(Map<String, dynamic> json) {
    return ScheduleInfo(
      date: json['date'],
      time: json['time'],
      dayName: json['day_name'],
      formattedDate: json['formatted_date'],
      formattedDatetime: json['formatted_datetime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'time': time,
      'day_name': dayName,
      'formatted_date': formattedDate,
      'formatted_datetime': formattedDatetime,
    };
  }

  DateTime get dateTime {
    try {
      return DateTime.parse('$date $time:00');
    } catch (e) {
      return DateTime.now();
    }
  }
}

class BookingDetails {
  final String? alamat;
  final String? alamatLengkap;
  final String? email;
  final String? telepon;
  final double totalAmount;
  final double ongkosKirim;
  final double serviceFee;
  final String? formattedAmount;
  final String? formattedServiceFee;
  final String? formattedDeliveryFee;

  BookingDetails({
    this.alamat,
    this.alamatLengkap,
    this.email,
    this.telepon,
    required this.totalAmount,
    required this.ongkosKirim,
    required this.serviceFee,
    this.formattedAmount,
    this.formattedServiceFee,
    this.formattedDeliveryFee,
  });

  factory BookingDetails.fromJson(Map<String, dynamic> json) {
    final totalAmount = _parseDouble(json['total_amount']);
    final ongkosKirim = _parseDouble(json['ongkos_kirim']);
    final serviceFee = _parseDouble(json['service_fee']);

    return BookingDetails(
      alamat: json['alamat'],
      alamatLengkap: json['alamat_lengkap'],
      email: json['email'],
      telepon: json['telepon'],
      totalAmount: totalAmount,
      ongkosKirim: ongkosKirim,
      serviceFee: serviceFee,
      formattedAmount: json['formatted_amount'],
      formattedServiceFee: json['formatted_service_fee'],
      formattedDeliveryFee: json['formatted_delivery_fee'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alamat': alamat,
      'alamat_lengkap': alamatLengkap,
      'email': email,
      'telepon': telepon,
      'total_amount': totalAmount,
      'ongkos_kirim': ongkosKirim,
      'service_fee': serviceFee,
      'formatted_amount': formattedAmount,
      'formatted_service_fee': formattedServiceFee,
      'formatted_delivery_fee': formattedDeliveryFee,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}

// Schedule model untuk barber
class Schedule {
  final int id;
  final DateTime tanggal;
  final String jam;
  final bool isBooked;
  final BookingInfo? bookingInfo;

  Schedule({
    required this.id,
    required this.tanggal,
    required this.jam,
    this.isBooked = false,
    this.bookingInfo,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      tanggal: DateTime.parse(json['tanggal']),
      jam: json['jam'],
      isBooked: json['is_booked'] ?? false,
      bookingInfo: json['booking_info'] != null 
          ? BookingInfo.fromJson(json['booking_info']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tanggal': tanggal.toIso8601String().split('T')[0],
      'jam': jam,
      'is_booked': isBooked,
      'booking_info': bookingInfo?.toJson(),
    };
  }
}

class BookingInfo {
  final int id;
  final String pelangganNama;
  final double nominal;

  BookingInfo({
    required this.id,
    required this.pelangganNama,
    required this.nominal,
  });

  factory BookingInfo.fromJson(Map<String, dynamic> json) {
    return BookingInfo(
      id: json['id'],
      pelangganNama: json['pelanggan_nama'] ?? 'Unknown',
      nominal: double.tryParse(json['nominal'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pelanggan_nama': pelangganNama,
      'nominal': nominal,
    };
  }
}

// Available slot untuk customer
class AvailableSlot {
  final int id;
  final String jam;
  final String displayTime;

  AvailableSlot({
    required this.id,
    required this.jam,
    required this.displayTime,
  });

  factory AvailableSlot.fromJson(Map<String, dynamic> json) {
    return AvailableSlot(
      id: json['id'],
      jam: json['jam'],
      displayTime: json['display_time'] ?? json['jam'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jam': jam,
      'display_time': displayTime,
    };
  }
}

// Barber untuk customer search
class BarberSearch {
  final int id;
  final String nama;
  final String? spesialisasi;
  final double harga;
  final double rating;
  final int totalReviews;
  final String formattedHarga;
  final DateTime createdAt;

  BarberSearch({
    required this.id,
    required this.nama,
    this.spesialisasi,
    required this.harga,
    required this.rating,
    required this.totalReviews,
    required this.formattedHarga,
    required this.createdAt,
  });

  factory BarberSearch.fromJson(Map<String, dynamic> json) {
    return BarberSearch(
      id: json['id'],
      nama: json['nama'],
      spesialisasi: json['spesialisasi'],
      harga: double.tryParse(json['harga'].toString()) ?? 0.0,
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      totalReviews: json['total_reviews'] ?? 0,
      formattedHarga: json['formatted_harga'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'spesialisasi': spesialisasi,
      'harga': harga,
      'rating': rating,
      'total_reviews': totalReviews,
      'formatted_harga': formattedHarga,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Pagination info
class PaginationInfo {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final bool hasMore;

  PaginationInfo({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.hasMore,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['current_page'],
      lastPage: json['last_page'],
      perPage: json['per_page'],
      total: json['total'],
      hasMore: json['has_more'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'last_page': lastPage,
      'per_page': perPage,
      'total': total,
      'has_more': hasMore,
    };
  }
}