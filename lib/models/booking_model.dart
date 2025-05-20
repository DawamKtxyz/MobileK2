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
  final String pelangganNama;
  
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
    this.pelangganNama = 'Tidak tersedia', // Default value
  });

  factory Booking.fromJson(Map<String, dynamic> json) {

     Map<String, dynamic> barberData = {};
  Map<String, dynamic> scheduleData = {};
  Map<String, dynamic> bookingDetailsData = {};
  
    if (json['jadwal'] != null) {
    // Respons dari getMyBookings()
    scheduleData = {
      'date': json['jadwal']['tanggal'] ?? '',
      'time': json['jadwal']['jam'] ?? '',
    };
  } else if (json['schedule'] != null) {
    // Alternatif format
    scheduleData = json['schedule'];
  }
  
  if (json['barber'] != null) {
    barberData = json['barber'];
  } else if (json['tukang_cukur'] != null) {
    barberData = json['tukang_cukur'];
  } else {
    // Jika tidak ada data barber, buat barber default dari id_barber
    if (json['id_barber'] != null) {
  var barberId = json['id_barber'];
  if (barberId is String) {
    barberId = int.tryParse(barberId) ?? 0;
  }
  barberData = {
    'id': barberId,
    'nama': 'Barber #$barberId',
  };
} else {
      barberData = {'id': 0, 'nama': 'Unknown Barber'};
    }
  }
  
  // Persiapkan data booking details
  if (json['booking_details'] != null) {
    bookingDetailsData = json['booking_details'];
  } else if (json['booking_info'] != null) {
    bookingDetailsData = json['booking_info'];
  } else {
    // Buat booking details dari data yang tersedia
    bookingDetailsData = {
      'alamat_lengkap': json['alamat_lengkap'],
      'email': json['email'],
      'telepon': json['telepon'],
      'total_amount': json['nominal'],
      'ongkos_kirim': json['ongkos_kirim'] ?? 0,
      'service_fee': (json['nominal'] != null && json['ongkos_kirim'] != null) 
          ? (double.tryParse(json['nominal'].toString()) ?? 0) - 
            (double.tryParse(json['ongkos_kirim'].toString()) ?? 0)
          : 0,
    };
  }

   String pelangganNama = 'Tidak tersedia';
  if (json['pelanggan'] != null && json['pelanggan']['nama'] != null) {
    pelangganNama = json['pelanggan']['nama'];
  } else if (json['id_pelanggan'] != null) {
    pelangganNama = 'Pelanggan #${json['id_pelanggan']}';
  }

  // Tentukan status booking berdasarkan tanggal
  String status = json['status'] ?? 'pending';
  if (status == 'pending' && scheduleData['date'] != null) {
    try {
      DateTime bookingDate = DateTime.parse(scheduleData['date']);
      if (bookingDate.isBefore(DateTime.now())) {
        status = 'completed';
      } else {
        status = 'upcoming';
      }
    } catch (e) {
      // Jika parsing gagal, gunakan default
      status = 'upcoming';
    }
  }

  // Tentukan apakah booking bisa dibatalkan
  bool canCancel = json['can_cancel'] ?? false;
  if (!canCancel && status == 'upcoming') {
    canCancel = true; // Defaultnya booking yang upcoming bisa dibatalkan
  }

  // Hitung waktu tersisa sampai janji
  String? timeUntilAppointment;
  if (json['time_until_appointment'] != null) {
    timeUntilAppointment = json['time_until_appointment'];
  } else if (scheduleData['date'] != null && scheduleData['time'] != null) {
    try {
      DateTime bookingDateTime = DateTime.parse('${scheduleData['date']} ${scheduleData['time']}:00');
      Duration timeLeft = bookingDateTime.difference(DateTime.now());
      
      if (timeLeft.isNegative) {
        timeUntilAppointment = "Sudah lewat";
      } else if (timeLeft.inDays > 0) {
        timeUntilAppointment = "${timeLeft.inDays} hari lagi";
      } else if (timeLeft.inHours > 0) {
        timeUntilAppointment = "${timeLeft.inHours} jam lagi";
      } else if (timeLeft.inMinutes > 0) {
        timeUntilAppointment = "${timeLeft.inMinutes} menit lagi";
      } else {
        timeUntilAppointment = "Sebentar lagi";
      }
    } catch (e) {
      // Jika parsing gagal, biarkan null
    }
  }

  return Booking(
    id: json['id'] ?? 0,
    idTransaksi: json['id_transaksi'] ?? 'Unknown',
    barber: BarberInfo.fromJson(barberData),
    schedule: ScheduleInfo.fromJson(scheduleData),
    bookingDetails: BookingDetails.fromJson(bookingDetailsData),
    status: status,
    canCancel: canCancel,
    createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now(),
    timeUntilAppointment: timeUntilAppointment,
     pelangganNama: pelangganNama, // Tambahkan ini
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
    // Convert id to int if it's a string
    int id;
    if (json['id'] is String) {
      id = int.tryParse(json['id']) ?? 0;
    } else {
      id = json['id'] ?? 0;
    }
    
    return BarberInfo(
      id: id,
      nama: json['nama'] ?? 'Unknown',
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

  // Factory method untuk default value
  factory BarberInfo.defaultValue() {
    return BarberInfo(
      id: 0,
      nama: 'Unknown Barber',
    );
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
  String date = '';
  String time = '';
  
  // Handle berbagai format date dan time
  if (json['date'] != null) {
    date = json['date']; 
  } else if (json['tanggal'] != null) {
    // Jika format tanggal adalah datetime (seperti dari DB)
    String tanggalStr = json['tanggal'].toString();
    if (tanggalStr.contains('T')) {
      date = tanggalStr.split('T')[0];
    } else {
      date = tanggalStr;
    }
  }
  
  if (json['time'] != null) {
    time = json['time'].toString();
  } else if (json['jam'] != null) {
    time = json['jam'].toString();
    // Jika jam masih dalam format datetime, ekstrak waktu saja
    if (time.contains(':00.000000Z')) {
      time = time.split(':00.000000Z')[0];
    }
  }
  
  // Generate formattedDate jika tidak ada
  String? formattedDate = json['formatted_date']?.toString();
  if (formattedDate == null && date.isNotEmpty) {
    try {
      final dateObj = DateTime.parse(date);
      formattedDate = "${dateObj.day}/${dateObj.month}/${dateObj.year}";
    } catch (e) {
      // Biarkan null jika parsing gagal
    }
  }
  
  return ScheduleInfo(
    date: date,
    time: time,
    dayName: json['day_name']?.toString(),
    formattedDate: formattedDate,
    formattedDatetime: json['formatted_datetime']?.toString(),
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
  // Convert id to int if it's a string
  int id;
  if (json['id'] is String) {
    id = int.tryParse(json['id']) ?? 0;
  } else {
    id = json['id'] ?? 0;
  }
  
  // Parse nominal safely
  double nominal = 0.0;
  if (json['nominal'] != null) {
    if (json['nominal'] is String) {
      nominal = double.tryParse(json['nominal']) ?? 0.0;
    } else if (json['nominal'] is num) {
      nominal = (json['nominal'] as num).toDouble();
    }
  }
  
  return BookingInfo(
    id: id,
    pelangganNama: json['pelanggan_nama']?.toString() ?? 'Unknown',
    nominal: nominal,
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
  // Di kelas Booking, tambahkan static method:
static T? _safelyParseProperty<T>(dynamic value, T defaultValue) {
  if (value == null) return defaultValue;
  if (value is T) return value;
  
  // Konversi khusus untuk beberapa tipe
  if (T == int) {
    if (value is String) {
      return int.tryParse(value) as T? ?? defaultValue;
    }
    if (value is double) {
      return value.toInt() as T? ?? defaultValue;
    }
  }
  
  if (T == double) {
    if (value is String) {
      return double.tryParse(value) as T? ?? defaultValue;
    }
    if (value is int) {
      return value.toDouble() as T? ?? defaultValue;
    }
  }
  
  if (T == String) {
    return value.toString() as T? ?? defaultValue;
  }
  
  return defaultValue;
}
}
