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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
        ),
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
      appBar: AppBar(
        title: Text(_userType == UserType.barber ? 'Barber Dashboard' : 'Pelanggan Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[300],
                          child: Icon(
                            _userType == UserType.barber ? Icons.cut : Icons.person,
                            size: 40,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userData.nama,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _userData.email,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _userData.telepon ?? 'No Phone',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const Divider(height: 32),
                    
                    // Show different info based on user type
                    if (_userType == UserType.barber && _userData is Barber) ...[
                      _infoItem('Spesialisasi', (_userData as Barber).spesialisasi ?? 'Tidak ada'),
                      const SizedBox(height: 8),
                      _infoItem('Status Sertifikat', (_userData as Barber).sertifikat != null ? 'Tersedia' : 'Tidak ada'),
                    ] else if (_userType == UserType.pelanggan && _userData is Pelanggan) ...[
                      _infoItem('Alamat', (_userData as Pelanggan).alamat ?? 'Belum diisi'),
                      const SizedBox(height: 8),
                      _infoItem('Tanggal Lahir', (_userData as Pelanggan).tanggalLahir ?? 'Belum diisi'),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Different dashboard content based on user type
            if (_userType == UserType.barber) ...[
              _buildBarberDashboard(),
            ] else if (_userType == UserType.pelanggan) ...[
              _buildPelangganDashboard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  Widget _buildBarberDashboard() {
    // Barber-specific dashboard content
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Layanan Barber',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // Mock content - in a real app, this would be dynamic
        _buildActionCard(
          title: 'Layanan Saya',
          icon: Icons.cut,
          subtitle: 'Kelola jenis layanan yang disediakan',
          onTap: () {
            // Navigate to services management
          },
        ),
        _buildActionCard(
          title: 'Jadwal & Booking',
          icon: Icons.calendar_today,
          subtitle: 'Lihat dan kelola booking pelanggan',
          onTap: () {
            // Navigate to bookings
          },
        ),
        _buildActionCard(
          title: 'Profil Barber',
          icon: Icons.person,
          subtitle: 'Perbarui informasi profil Anda',
          onTap: () {
            // Navigate to profile edit
          },
        ),
      ],
    );
  }

  Widget _buildPelangganDashboard() {
    // Customer-specific dashboard content
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Layanan Pelanggan',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // Mock content - in a real app, this would be dynamic
        _buildActionCard(
          title: 'Cari Barber',
          icon: Icons.search,
          subtitle: 'Temukan barber terbaik di sekitar Anda',
          onTap: () {
            // Navigate to barber search
          },
        ),
        _buildActionCard(
          title: 'Booking Saya',
          icon: Icons.calendar_today,
          subtitle: 'Lihat dan kelola booking Anda',
          onTap: () {
            // Navigate to bookings
          },
        ),
        _buildActionCard(
          title: 'Profil Saya',
          icon: Icons.person,
          subtitle: 'Perbarui informasi profil Anda',
          onTap: () {
            // Navigate to profile edit
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}