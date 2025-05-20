import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/barber_model.dart';
import '../models/pelanggan_model.dart';
import '../models/booking_model.dart';
import '../services/auth_service_factory.dart';
import '../services/barber_service.dart';
import '../services/pelanggan_service.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserType? _userType;
  dynamic _userData;
  bool _isLoading = true;
  int _selectedIndex = 0;
  String _selectedFilter = 'Semua';

  // Services
  final BarberService _barberService = BarberService();
  final PelangganService _pelangganService = PelangganService();

  // Data storage
  List<BarberSearch> _barbers = [];
  List<Booking> _bookings = [];
  Map<String, List<Schedule>> _schedules = {};
  Map<String, dynamic>? _stats;
  
  // UI State
  bool _isLoadingData = false;
  String _searchQuery = '';
  String _selectedDate = DateTime.now().toIso8601String().split('T')[0];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userTypeString = prefs.getString('user_type');
      
      if (userTypeString == 'barber') {
        setState(() => _userType = UserType.barber);
        
        final barberJson = prefs.getString('barber');
        if (barberJson != null) {
          final barberMap = json.decode(barberJson);
          setState(() => _userData = Barber.fromJson(barberMap));
          await _loadBarberData();
        }
      } else if (userTypeString == 'pelanggan') {
        setState(() => _userType = UserType.pelanggan);
        
        final pelangganJson = prefs.getString('pelanggan');
        if (pelangganJson != null) {
          final pelangganMap = json.decode(pelangganJson);
          setState(() => _userData = Pelanggan.fromJson(pelangganMap));
          await _loadPelangganData();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBarberData() async {
  try {
    setState(() => _isLoadingData = true);
    
    // Inisialisasi nilai default untuk stats terlebih dahulu
    setState(() => _stats = {
      'total_bookings_today': 0,
      'available_slots_today': 0,
      'total_bookings_this_month': 0,
      'formatted_revenue_this_month': 'Rp 0'
    });

    // Debug print untuk user ID
    print('Debug - User ID: ${_userData?.id}');

    // Get schedules with full error handling
    try {
      final schedulesData = await _barberService.getMySchedules();
      print('Debug - Schedules Response: $schedulesData');
      
      if (schedulesData != null && schedulesData['success'] == true && schedulesData['schedules'] != null) {
        final schedulesResponse = schedulesData['schedules'];
        final Map<String, List<Schedule>> formattedSchedules = {};
        
        if (schedulesResponse is Map<String, dynamic>) {
          schedulesResponse.forEach((date, scheduleList) {
            if (scheduleList is List) {
              formattedSchedules[date] = scheduleList
                  .map((item) => Schedule.fromJson(item))
                  .toList();
            }
          });
        }
        
        setState(() => _schedules = formattedSchedules);
      }
    } catch (scheduleError) {
      print('Debug - Error loading schedules: $scheduleError');
    }

    // Get bookings with full error handling
   try {
  final bookingsData = await _barberService.getMyBookings();
  print('Debug - Bookings Response: $bookingsData');
  
  if (bookingsData != null && bookingsData['success'] == true && bookingsData['bookings'] != null) {
    final bookingsList = bookingsData['bookings'];
    if (bookingsList is List) {
      // Tambahkan try-catch di sini untuk menangkap error pada setiap item
      final processedBookings = <Booking>[];
      for (var item in bookingsList) {
        try {
          processedBookings.add(Booking.fromJson(item));
        } catch (e) {
          print('Debug - Error processing booking item: $e');
          // Skip item yang bermasalah
        }
      }
      setState(() => _bookings = processedBookings);
    }
  }
} catch (bookingError) {
  print('Debug - Error loading bookings: $bookingError');
}

    // Get stats with full error handling
    try {
      // Verifikasi ID terlebih dahulu
      if (_userData?.id == null) {
        print('Debug - User ID is null, skipping stats');
        return;
      }
      
      print('Debug - Before getStats call');
      final statsData = await _barberService.getStats(_userData.id);
      print('Debug - Stats Response: $statsData');
      
      if (statsData != null && statsData['success'] == true && statsData['stats'] != null) {
        setState(() => _stats = statsData['stats']);
      }
    } catch (statError) {
      print('Debug - Error loading stats data: $statError');
    }
    
  } catch (e) {
    print('Debug - General error in _loadBarberData: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error loading barber data: $e')),
    );
  } finally {
    setState(() => _isLoadingData = false);
  }
}

  Future<void> _loadPelangganData() async {
    try {
      setState(() => _isLoadingData = true);

      // Load barbers and bookings in parallel
      final futures = await Future.wait([
        _pelangganService.searchBarbers(search: _searchQuery),
        _pelangganService.getMyBookings(),
      ]);

      final barbersData = futures[0];
      final bookingsData = futures[1];

      if (barbersData['success']) {
        final barbersDataList = barbersData['data'];
        if (barbersDataList is List) {
          setState(() => _barbers = barbersDataList
              .map((item) => BarberSearch.fromJson(item))
              .toList());
        }
      }

      if (bookingsData['success']) {
        final bookingsList = bookingsData['bookings'];
        if (bookingsList is List) {
          setState(() => _bookings = bookingsList
              .map((item) => Booking.fromJson(item))
              .toList());
        }
      }
    } catch (e) {
      print('Debug - Error loading customer data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading customer data: $e')),
      );
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _searchBarbers(String query) async {
    setState(() => _searchQuery = query);
    
    try {
      setState(() => _isLoadingData = true);

      final result = await _pelangganService.searchBarbers(
        search: query.isEmpty ? null : query,
      );

      if (result['success']) {
        setState(() => _barbers = (result['data'] as List)
            .map((item) => BarberSearch.fromJson(item))
            .toList());
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching barbers: $e')),
      );
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _addTimeSlot() async {
    await showDialog(
      context: context,
      builder: (context) => _AddTimeSlotDialog(
        onAddSlot: (date, time) async {
          try {
            final result = await _barberService.addTimeSlot(
              tanggal: date,
              jam: time,
            );

            if (result['success']) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result['message'])),
              );
              await _loadBarberData(); // Refresh data
            } else {
              throw Exception(result['message']);
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error adding time slot: $e')),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteTimeSlot(Schedule schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Slot Waktu'),
        content: Text('Apakah Anda yakin ingin menghapus slot ${schedule.jam} pada ${schedule.tanggal.day}/${schedule.tanggal.month}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await _barberService.deleteTimeSlot(schedule.id);

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
          await _loadBarberData(); // Refresh data
        } else {
          throw Exception(result['message']);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting time slot: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      await AuthServiceFactory.logout();
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _showBarberDetails(BarberSearch barber) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BarberDetailsBottomSheet(
        barber: barber,
        onBookingTap: () {
          Navigator.pop(context);
          _showBookingDialog(barber);
        },
      ),
    );
  }

  void _showBookingDialog(BarberSearch barber) {
    showDialog(
      context: context,
      builder: (context) => _BookingDialog(
        barber: barber,
        pelangganService: _pelangganService,
        onBookingSuccess: () {
          _loadPelangganData(); // Refresh bookings
        },
      ),
    );
  }

  void _showBookingDetails(Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BookingDetailsBottomSheet(
        booking: booking,
        onCancel: booking.canCancel ? () => _cancelBooking(booking) : null,
      ),
    );
  }

  Future<void> _cancelBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Booking'),
        content: Text('Apakah Anda yakin ingin membatalkan booking dengan ${booking.barber.nama}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await _pelangganService.cancelBooking(booking.id);

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
          await _loadPelangganData(); // Refresh bookings
          Navigator.pop(context); // Close bottom sheet if open
        } else {
          throw Exception(result['message']);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling booking: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If no user data is found, redirect to login
    if (_userType == null || _userData == null) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
      
      return const Scaffold(
        body: Center(
          child: Text('Redirecting to login...'),
        ),
      );
    }

    // Build UI based on user type
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomePage(),
            _buildBookingsPage(),
            _buildProfilePage(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: [
          BottomNavigationBarItem(
            icon: Icon(_userType == UserType.barber ? Icons.home : Icons.search),
            label: _userType == UserType.barber ? 'Home' : 'Cari',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Booking',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top section with greeting and profile
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${_userData.nama.split(' ')[0]}!',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userType == UserType.barber
                          ? 'Selamat datang di dashboard barber Anda'
                          : 'Temukan barber terbaik untuk Anda',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = 2; // Switch to profile tab
                  });
                },
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  child: Icon(
                    _userType == UserType.barber ? Icons.content_cut : Icons.person,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Loading indicator if data is being loaded
          if (_isLoadingData)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            // Dashboard content based on user type
            _userType == UserType.barber 
                ? _buildBarberDashboardContent() 
                : _buildPelangganDashboardContent(),
        ],
      ),
    );
  }

  Widget _buildBarberDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                const Color(0xFF2563EB),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.verified,
                    color: Colors.white.withOpacity(0.9),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Status Barber',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tersedia',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Aktif',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Harga',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            PelangganService.formatPrice((_userData as Barber).harga),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),

        // Statistics cards if available
        if (_stats != null) ...[
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Booking Hari Ini',
                  _stats!['total_bookings_today'].toString(),
                  Icons.today,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Slot Tersedia',
                  _stats!['available_slots_today'].toString(),
                  Icons.schedule,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Booking Bulan Ini',
                  _stats!['total_bookings_this_month'].toString(),
                  Icons.calendar_month,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pendapatan',
                  _stats!['formatted_revenue_this_month'] ?? 'Rp 0',
                  Icons.attach_money,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        
        // Specializations
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spesialisasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.content_cut,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    (_userData as Barber).spesialisasi ?? 'Tidak ada spesialisasi',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Quick access
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Akses Cepat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAccessCard(
                    'Tambah Jadwal',
                    Icons.add_circle_outline,
                    Colors.green,
                    _addTimeSlot,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAccessCard(
                    'Lihat Booking',
                    Icons.calendar_today,
                    Colors.blue,
                    () {
                      setState(() {
                        _selectedIndex = 1; // Navigate to bookings tab
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAccessCard(
                    'Kelola Jadwal',
                    Icons.schedule,
                    Colors.purple,
                    () {
                      setState(() {
                        _selectedIndex = 1; // Navigate to bookings tab
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAccessCard(
                    'Edit Profil',
                    Icons.person,
                    Colors.orange,
                    () {
                      setState(() {
                        _selectedIndex = 2; // Navigate to profile tab
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPelangganDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            onChanged: _searchBarbers,
            decoration: InputDecoration(
              hintText: 'Cari barber ...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: InputBorder.none,
              icon: Icon(
                Icons.search,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Filter options
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Semua', true),
              _buildFilterChip('Terdekat', false),
              _buildFilterChip('Rating Tertinggi', false),
              _buildFilterChip('Harga Terendah', false),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Featured barbers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Barber Tersedia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_barbers.isNotEmpty)
              Text(
                '${_barbers.length} barber',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Barber list
        _barbers.isEmpty
            ? Center(
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isEmpty ? 'Tidak ada barber' : 'Tidak ada hasil',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchQuery.isEmpty 
                          ? 'Belum ada barber yang tersedia saat ini'
                          : 'Coba kata kunci yang berbeda',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : Column(
                children: _barbers.map((barber) => _buildBarberCard(barber)).toList(),
              ),
      ],
    );
  }

  Widget _buildBookingsPage() {
    return _userType == UserType.barber 
        ? _buildBarberBookingsPage() 
        : _buildPelangganBookingsPage();
  }

  Widget _buildBarberBookingsPage() {
    final todaysSchedules = _schedules[_selectedDate] ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Jadwal & Booking',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _loadBarberData,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Tab selection
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 5,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Jadwal Saya',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Booking Masuk',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Date selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: PelangganService.getAvailableDates()
                  .map((dateInfo) => _buildDateCard(
                        dateInfo['day_short'],
                        dateInfo['day_number'],
                        dateInfo['date'] == _selectedDate,
                        () {
                          setState(() {
                            _selectedDate = dateInfo['date'];
                          });
                        },
                      ))
                  .toList(),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Time slots for selected date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Waktu Tersedia',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _addTimeSlot,
                icon: const Icon(Icons.add),
                label: const Text('Tambah'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (todaysSchedules.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Icon(
                    Icons.schedule,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada jadwal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tambahkan jadwal untuk hari ini',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _addTimeSlot,
                    child: const Text('Tambah Jadwal'),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: todaysSchedules.map((schedule) => 
                _buildTimeSlotChip(schedule)
              ).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPelangganBookingsPage() {
    final activeBookings = _bookings.where((b) => b.status == 'upcoming').toList();
    final historyBookings = _bookings.where((b) => b.status == 'completed').toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Booking Saya',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _loadPelangganData,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Tab selection
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 5,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Aktif (${activeBookings.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Riwayat (${historyBookings.length})',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Bookings list
          if (activeBookings.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  Icon(
                    Icons.calendar_today,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada booking aktif',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Anda belum memiliki booking yang aktif saat ini',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 0; // Go to home to book
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cari Barber',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: activeBookings.map((booking) => _buildBookingCard(booking)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profil',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Profile card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Profile picture
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  child: Icon(
                    _userType == UserType.barber ? Icons.content_cut : Icons.person,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Name
                Text(
                  _userData.nama,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Role
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _userType == UserType.barber ? 'Barber' : 'Pelanggan',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Contact information
                _buildProfileInfoItem(
                  'Email',
                  _userData.email,
                  Icons.email_outlined,
                ),
                
                const Divider(height: 24),
                
                _buildProfileInfoItem(
                  'Telepon',
                  _userData.telepon ?? 'Belum diisi',
                  Icons.phone_outlined,
                ),
                
                if (_userType == UserType.pelanggan && _userData is Pelanggan) ...[
                  const Divider(height: 24),
                  _buildProfileInfoItem(
                    'Alamat',
                    (_userData as Pelanggan).alamat ?? 'Belum diisi',
                    Icons.location_on_outlined,
                  ),
                ] else if (_userType == UserType.barber && _userData is Barber) ...[
                  const Divider(height: 24),
                  _buildProfileInfoItem(
                    'Spesialisasi',
                    (_userData as Barber).spesialisasi ?? 'Belum diisi',
                    Icons.content_cut,
                  ),
                  const Divider(height: 24),
                  _buildProfileInfoItem(
                    'Harga Layanan',
                    PelangganService.formatPrice((_userData as Barber).harga),
                    Icons.attach_money,
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildProfileActionButton(
                  'Edit Profil',
                  Icons.edit,
                  Colors.blue,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(
                          userType: _userType!,
                          userData: _userData,
                        ),
                      ),
                    ).then((result) {
                      // Refresh data if profile was updated
                      if (result == true) {
                        _loadUserData();
                      }
                    });
                  },
                ),
                
                const Divider(height: 16),
                
                _buildProfileActionButton(
                  'Pengaturan',
                  Icons.settings,
                  Colors.orange,
                  () {
                    // TODO: Navigate to settings
                  },
                ),
                
                const Divider(height: 16),
                
                _buildProfileActionButton(
                  'Bantuan',
                  Icons.help_outline,
                  Colors.green,
                  () {
                    // TODO: Navigate to help
                  },
                ),
                
                const Divider(height: 16),
                
                _buildProfileActionButton(
                  'Keluar',
                  Icons.logout,
                  Colors.red,
                  _showLogoutConfirmation,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // App version
          Center(
            child: Text(
              'BarberGo v1.0.0',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBarberCard(BarberSearch barber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to barber details
            _showBarberDetails(barber);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.content_cut,
                    size: 32,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        barber.nama,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        barber.spesialisasi ?? 'Tidak ada spesialisasi',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            barber.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${barber.totalReviews})',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      barber.formattedHarga,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        _showBarberDetails(barber);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Lihat',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showBookingDetails(booking),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      booking.barber.nama,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(booking.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        booking.status == 'upcoming' ? 'Mendatang' : 'Selesai',
                        style: TextStyle(
                          color: _getStatusColor(booking.status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${booking.schedule.formattedDate} • ${booking.schedule.time}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      booking.bookingDetails.formattedAmount ?? 
                      PelangganService.formatPrice(booking.bookingDetails.totalAmount),
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (booking.timeUntilAppointment != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        booking.timeUntilAppointment!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                if (booking.canCancel) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _cancelBooking(booking),
                        child: Text(
                          'Batalkan',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlotChip(Schedule schedule) {
    final isBooked = schedule.isBooked;
    
    return InkWell(
      onLongPress: !isBooked ? () => _deleteTimeSlot(schedule) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isBooked ? Colors.grey[200] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isBooked ? Colors.grey[300]! : Theme.of(context).primaryColor,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              schedule.jam,
              style: TextStyle(
                color: isBooked ? Colors.grey[500] : Colors.black,
                fontWeight: FontWeight.bold,
                decoration: isBooked ? TextDecoration.lineThrough : null,
              ),
            ),
            if (isBooked && schedule.bookingInfo != null) ...[
              const SizedBox(height: 4),
              Text(
                schedule.bookingInfo!.pelangganNama,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard(String day, String date, bool isSelected, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 60,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  day,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          // Handle filter selection
          setState(() {
            _selectedFilter = label;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        checkmarkColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

Color _getStatusColor(String status) {
  switch (status) {
    case 'upcoming':
      return Colors.blue;
    case 'completed':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

// Dialog untuk menambah time slot (barber)
class _AddTimeSlotDialog extends StatefulWidget {
  final Function(String, String) onAddSlot;

  const _AddTimeSlotDialog({required this.onAddSlot});

  @override
  State<_AddTimeSlotDialog> createState() => __AddTimeSlotDialogState();
}

class __AddTimeSlotDialogState extends State<_AddTimeSlotDialog> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Slot Waktu'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Date picker
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Tanggal'),
            subtitle: Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
          ),
          
          // Time picker
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Waktu'),
            subtitle: Text(
              '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
            ),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (time != null) {
                setState(() => _selectedTime = time);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () async {
            setState(() => _isLoading = true);
            
            final dateStr = _selectedDate.toIso8601String().split('T')[0];
            final timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
            
            await widget.onAddSlot(dateStr, timeStr);
            
            if (mounted) {
              Navigator.pop(context);
            }
          },
          child: _isLoading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Tambah'),
        ),
      ],
    );
  }
}

// Bottom sheet untuk detail barber (customer)
class _BarberDetailsBottomSheet extends StatelessWidget {
  final BarberSearch barber;
  final VoidCallback onBookingTap;

  const _BarberDetailsBottomSheet({
    required this.barber,
    required this.onBookingTap,
  });

  @override
Widget build(BuildContext context) {
  return Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
                
                const SizedBox(height: 24),
                
                // Barber profile
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.content_cut,
                        size: 40,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            barber.nama,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            barber.spesialisasi ?? 'Tidak ada spesialisasi',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                barber.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${barber.totalReviews} ulasan)',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Price section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Harga Layanan',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            barber.formattedHarga,
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Ongkos Kirim',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Rp 10.000',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // About section (mockup)
                const Text(
                  'Tentang Barber',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Barber profesional dengan pengalaman lebih dari 5 tahun. Spesialisasi dalam berbagai gaya rambut modern dan klasik. Menggunakan peralatan berkualitas tinggi dan produk terbaik untuk hasil yang memuaskan.',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Services section (mockup)
                const Text(
                  'Layanan Tersedia',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildServiceChip('Potong Rambut'),
                    _buildServiceChip('Keramas'),
                    _buildServiceChip('Styling'),
                    _buildServiceChip('Cukur Jenggot'),
                    _buildServiceChip('Hair Treatment'),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Book button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onBookingTap,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Book Sekarang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceChip(String service) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        service,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// Dialog untuk booking (customer)
class _BookingDialog extends StatefulWidget {
  final BarberSearch barber;
  final PelangganService pelangganService;
  final VoidCallback onBookingSuccess;

  const _BookingDialog({
    required this.barber,
    required this.pelangganService,
    required this.onBookingSuccess,
  });

  @override
  State<_BookingDialog> createState() => __BookingDialogState();
}

class __BookingDialogState extends State<_BookingDialog> {
  DateTime _selectedDate = DateTime.now();
  AvailableSlot? _selectedSlot;
  List<AvailableSlot> _availableSlots = [];
  
  final _alamatController = TextEditingController();
  final _emailController = TextEditingController();
  final _teleponController = TextEditingController();
  
  bool _isLoadingSlots = false;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadAvailableSlots();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final pelangganJson = prefs.getString('pelanggan');
    
    if (pelangganJson != null) {
      final pelanggan = Pelanggan.fromJson(json.decode(pelangganJson));
      _emailController.text = pelanggan.email;
      _teleponController.text = pelanggan.telepon ?? '';
      _alamatController.text = pelanggan.alamat ?? '';
    }
  }

  Future<void> _loadAvailableSlots() async {
    setState(() => _isLoadingSlots = true);
    
    try {
      final dateStr = _selectedDate.toIso8601String().split('T')[0];
      final result = await widget.pelangganService.getBarberAvailableSlots(
        barberId: widget.barber.id,
        date: dateStr,
      );

      if (result['success']) {
        setState(() {
          _availableSlots = (result['available_slots'] as List)
              .map((item) => AvailableSlot.fromJson(item))
              .toList();
          _selectedSlot = null; // Reset selection when date changes
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading slots: $e')),
      );
    } finally {
      setState(() => _isLoadingSlots = false);
    }
  }

  Future<void> _makeBooking() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih waktu terlebih dahulu')),
      );
      return;
    }

    if (_alamatController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat harus diisi')),
      );
      return;
    }

    setState(() => _isBooking = true);

    try {
      final result = await widget.pelangganService.createBooking(
        barberId: widget.barber.id,
        jadwalId: _selectedSlot!.id,
        alamatLengkap: _alamatController.text,
        email: _emailController.text,
        telepon: _teleponController.text,
        ongkosKirim: 10000, // Default delivery fee
      );

      if (result['success']) {
        Navigator.pop(context);
        widget.onBookingSuccess();
        
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Booking Berhasil!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Booking Anda dengan ${widget.barber.nama} telah dikonfirmasi.'),
                const SizedBox(height: 8),
                Text('ID Transaksi: ${result['booking']['id_transaksi']}'),
                const SizedBox(height: 8),
                Text('Total: ${result['booking']['total_amount'] != null ? PelangganService.formatPrice(result['booking']['total_amount']) : ""}'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        throw Exception(result['message'] ?? 'Booking failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error making booking: $e')),
      );
    } finally {
      setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Book ${widget.barber.nama}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date selection
            const Text(
              'Pilih Tanggal',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null && date != _selectedDate) {
                  setState(() => _selectedDate = date);
                  await _loadAvailableSlots();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Time slots
            const Text(
              'Pilih Waktu',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            if (_isLoadingSlots)
              const Center(child: CircularProgressIndicator())
            else if (_availableSlots.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('Tidak ada waktu tersedia'),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableSlots.map((slot) => 
                  FilterChip(
                    label: Text(slot.displayTime),
                    selected: _selectedSlot?.id == slot.id,
                    onSelected: (selected) {
                      setState(() {
                        _selectedSlot = selected ? slot : null;
                      });
                    },
                  )
                ).toList(),
              ),
            
            const SizedBox(height: 16),
            
            // Contact information
            const Text(
              'Informasi Kontak',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _teleponController,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _alamatController,
              decoration: const InputDecoration(
                labelText: 'Alamat Lengkap',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            // Price summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Harga Layanan'),
                      Text(widget.barber.formattedHarga),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Ongkos Kirim'),
                      Text('Rp 10.000'),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        PelangganService.formatPrice(widget.barber.harga + 10000),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isBooking ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isBooking ? null : _makeBooking,
          child: _isBooking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Book Sekarang'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _alamatController.dispose();
    _emailController.dispose();
    _teleponController.dispose();
    super.dispose();
  }
}

// Bottom sheet untuk detail booking (customer)
class _BookingDetailsBottomSheet extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onCancel;

  const _BookingDetailsBottomSheet({
    required this.booking,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detail Booking',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            'ID: ${booking.idTransaksi}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(booking.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        booking.status == 'upcoming' ? 'Mendatang' : 'Selesai',
                        style: TextStyle(
                          color: _getStatusColor(booking.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Barber info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.content_cut,
                          size: 30,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.barber.nama,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (booking.barber.spesialisasi != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                booking.barber.spesialisasi!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                            if (booking.barber.telepon != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    booking.barber.telepon!,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Schedule info
                _buildInfoSection(
                  'Jadwal Appointment',
                  [
                    _buildInfoRow(Icons.calendar_today, 'Tanggal', booking.schedule.formattedDate ?? booking.schedule.date),
                    _buildInfoRow(Icons.access_time, 'Waktu', booking.schedule.time),
                    if (booking.timeUntilAppointment != null)
                      _buildInfoRow(Icons.timer, 'Waktu Tersisa', booking.timeUntilAppointment!),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Contact info
                _buildInfoSection(
                  'Informasi Kontak',
                  [
                    if (booking.bookingDetails.email != null)
                      _buildInfoRow(Icons.email, 'Email', booking.bookingDetails.email!),
                    if (booking.bookingDetails.telepon != null)
                      _buildInfoRow(Icons.phone, 'Telepon', booking.bookingDetails.telepon!),
                    if (booking.bookingDetails.alamatLengkap != null)
                      _buildInfoRow(Icons.location_on, 'Alamat', booking.bookingDetails.alamatLengkap!),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Payment info
                _buildInfoSection(
                  'Rincian Pembayaran',
                  [
                    _buildInfoRow(
                      Icons.content_cut, 
                      'Harga Layanan', 
                      booking.bookingDetails.formattedServiceFee ?? 
                      PelangganService.formatPrice(booking.bookingDetails.serviceFee),
                    ),
                    _buildInfoRow(
                      Icons.delivery_dining, 
                      'Ongkos Kirim', 
                      booking.bookingDetails.formattedDeliveryFee ?? 
                      PelangganService.formatPrice(booking.bookingDetails.ongkosKirim),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Pembayaran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        booking.bookingDetails.formattedAmount ?? 
                        PelangganService.formatPrice(booking.bookingDetails.totalAmount),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Action buttons
                if (onCancel != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Batalkan Booking',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'upcoming':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}