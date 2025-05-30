class Constants {
  // Base URLs - gunakan localhost untuk development
  static const String baseUrl = 'http://localhost:8000/api';
  static const String storageUrl = 'http://localhost:8000/storage';
  
  // Alternative URLs untuk testing di device berbeda
  // static const String baseUrl = 'http://192.168.1.11:8000/api';
  // static const String storageUrl = 'http://192.168.1.11:8000/storage';
  
  // Atau jika menggunakan emulator Android:
  // static const String baseUrl = 'http://10.0.2.2:8000/api';
  // static const String storageUrl = 'http://10.0.2.2:8000/storage';

  /// Build storage URL dengan konsistensi
  static String buildStorageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    
    // Remove leading slash if exists
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    
    return '$storageUrl/$path';
  }

  /// Build profile photo URL specifically
   static String? buildProfilePhotoUrl(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) return null;
    
    // If it's already a full URL, return it as is
    if (photoPath.startsWith('http')) return photoPath;
    
    // Otherwise, construct the storage URL
    String baseUrl = Constants.baseUrl;
    if (baseUrl.endsWith('/api')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 4);
    }
    
    return '$baseUrl/storage/$photoPath';
  }

  // Headers untuk request
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-Requested-With': 'XMLHttpRequest',
  };

  // Default values
  static const double defaultDeliveryFee = 10000.0;
  static const int defaultBookingHours = 2; // Minimal hours before cancelling
  static const int maxBookingDays = 30; // Maximum days ahead for booking
  
  // Time slots
  static const List<String> availableTimeSlots = [
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

  // Working days (1 = Monday, 7 = Sunday)
  static const List<int> workingDays = [1, 2, 3, 4, 5, 6]; // Monday to Saturday
  
  // App info
  static const String appName = 'BarberGo';
  static const String appVersion = '1.0.0';
  
  // Validation rules
  static const int minPasswordLength = 6;
  static const int maxNameLength = 255;
  static const int maxPhoneLength = 15;
  
  // Error messages
  static const String networkError = 'Terjadi kesalahan jaringan. Silakan coba lagi.';
  static const String serverError = 'Terjadi kesalahan server. Silakan coba lagi nanti.';
  static const String validationError = 'Data yang dimasukkan tidak valid.';
  static const String notFoundError = 'Data tidak ditemukan.';
  static const String unauthorizedError = 'Anda tidak memiliki akses. Silakan login ulang.';
  
  // Success messages
  static const String loginSuccess = 'Login berhasil!';
  static const String registerSuccess = 'Registrasi berhasil!';
  static const String updateSuccess = 'Data berhasil diperbarui!';
  static const String deleteSuccess = 'Data berhasil dihapus!';
  static const String bookingSuccess = 'Booking berhasil dibuat!';
  static const String cancelSuccess = 'Booking berhasil dibatalkan!';
  
  // Image placeholder
  static const String placeholderImage = '/api/placeholder/400/320';
  
  // Cached data keys
  static const String keyUserType = 'user_type';
  static const String keyBarberData = 'barber';
  static const String keyPelangganData = 'pelanggan';
  static const String keyBarberToken = 'token';
  static const String keyPelangganToken = 'pelanggan_token';
  
  // Filter options
  static const List<String> sortOptions = [
    'nama',
    'harga_asc',
    'harga_desc',
  ];
  
  static const Map<String, String> sortLabels = {
    'nama': 'Nama A-Z',
    'harga_asc': 'Harga Terendah',
    'harga_desc': 'Harga Tertinggi',
  };
  
  // Currency formatter
  static String formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }
  
  // Date formatter
  static String formatDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
  
  static String formatDateShort(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  // Time formatter
  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
  
  // Day names
  static const List<String> dayNames = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
  ];
  
  static const List<String> dayNamesShort = [
    'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'
  ];
  
  static String getDayName(int weekday) {
    return dayNames[weekday - 1];
  }
  
  static String getDayNameShort(int weekday) {
    return dayNamesShort[weekday - 1];
  }
  
  // Validation helpers
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  static bool isValidPhone(String phone) {
    return RegExp(r'^[0-9+\-\s\(\)]{8,15}$').hasMatch(phone);
  }
  
  static bool isValidPassword(String password) {
    return password.length >= minPasswordLength;
  }
  
  // Debug mode
  static const bool debugMode = true; // Set to false in production
  
  // Log helper
  static void log(String message) {
    if (debugMode) {
      print('[BarberGo] $message');
    }
  }
}