// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/barber_model.dart';
import '../models/pelanggan_model.dart';
import '../services/auth_service_factory.dart';
import 'login_screen.dart';

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
        }
      } else if (userTypeString == 'pelanggan') {
        setState(() => _userType = UserType.pelanggan);
        
        final pelangganJson = prefs.getString('pelanggan');
        if (pelangganJson != null) {
          final pelangganMap = json.decode(pelangganJson);
          setState(() => _userData = Pelanggan.fromJson(pelangganMap));
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
                          const Text(
                            'Rp 20.000',
                            style: TextStyle(
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
                    () {
                      // Navigate to add schedule screen
                      setState(() {
                        _selectedIndex = 1; // Navigate to bookings tab
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAccessCard(
                    'Lihat Booking',
                    Icons.calendar_today,
                    Colors.blue,
                    () {
                      // Navigate to bookings screen
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
                    'Tambah Layanan',
                    Icons.design_services,
                    Colors.purple,
                    () {
                      // Navigate to add service screen
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAccessCard(
                    'Riwayat',
                    Icons.history,
                    Colors.orange,
                    () {
                      // Navigate to history screen
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
        const Text(
          'Barber Populer',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Mock barber cards
        _buildBarberCard(
          'Zidan Julian',
          'BURST FADE',
          '4.8',
          '(124)',
          'Rp 20.000',
        ),
        _buildBarberCard(
          'Dawam',
          'Burst Fade',
          '4.7',
          '(98)',
          'Rp 20.000',
        ),
        _buildBarberCard(
          'Ytta',
          'Agoo',
          '4.6',
          '(75)',
          'Rp 20.000',
        ),
      ],
    );
  }

 // Continuing from _buildBarberCard in dashboard_screen.dart
  Widget _buildBarberCard(
    String name,
    String specialization,
    String rating,
    String reviews,
    String price,
  ) {
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
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specialization,
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
                            rating,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            reviews,
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
                      price,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        // Book this barber
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Booking',
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

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          // Handle filter selection
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

  Widget _buildBookingsPage() {
    return _userType == UserType.barber 
        ? _buildBarberBookingsPage() 
        : _buildPelangganBookingsPage();
  }

  Widget _buildBarberBookingsPage() {
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
                onPressed: () {
                  // Refresh bookings
                },
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
              children: [
                _buildDateCard('Sen', '15', true),
                _buildDateCard('Sel', '16', false),
                _buildDateCard('Rab', '17', false),
                _buildDateCard('Kam', '18', false),
                _buildDateCard('Jum', '19', false),
                _buildDateCard('Sab', '20', false),
                _buildDateCard('Min', '21', false),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Time slots
          const Text(
            'Waktu Tersedia',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTimeSlotChip('08:00', false),
              _buildTimeSlotChip('09:00', true),
              _buildTimeSlotChip('10:00', false),
              _buildTimeSlotChip('11:00', false),
              _buildTimeSlotChip('13:00', false),
              _buildTimeSlotChip('14:00', false),
              _buildTimeSlotChip('15:00', true),
              _buildTimeSlotChip('16:00', false),
              _buildTimeSlotChip('17:00', false),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Add new time slot button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: () {
                // Add new time slot
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tambah Slot Waktu',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPelangganBookingsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Saya',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
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
                    child: const Center(
                      child: Text(
                        'Aktif',
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
                      'Riwayat',
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
          
          // Empty state or bookings list
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
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard(String day, String date, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 60,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Select this date
          },
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

  Widget _buildTimeSlotChip(String time, bool isBooked) {
    return Container(
      child: FilterChip(
        label: Text(time),
        selected: false,
        onSelected: isBooked 
            ? null 
            : (bool selected) {
                // Select this time slot
              },
        backgroundColor: isBooked ? Colors.grey[200] : Colors.white,
        disabledColor: Colors.grey[200],
        labelStyle: TextStyle(
          color: isBooked ? Colors.grey[500] : Colors.black,
          decoration: isBooked ? TextDecoration.lineThrough : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isBooked ? Colors.grey[300]! : Theme.of(context).primaryColor,
            width: 1,
          ),
        ),
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
                    // Navigate to edit profile
                  },
                ),
                
                const Divider(height: 16),
                
                _buildProfileActionButton(
                  'Pengaturan',
                  Icons.settings,
                  Colors.orange,
                  () {
                    // Navigate to settings
                  },
                ),
                
                const Divider(height: 16),
                
                _buildProfileActionButton(
                  'Bantuan',
                  Icons.help_outline,
                  Colors.green,
                  () {
                    // Navigate to help
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
