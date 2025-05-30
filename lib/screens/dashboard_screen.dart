import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/barber_model.dart';
import '../models/booking_model.dart';
import '../models/pelanggan_model.dart';
import '../models/penggajian_model.dart';
import '../screens/chat_list_screen.dart';
import '../screens/direct_chat_screen.dart';
import '../screens/payment_screen.dart';
import '../services/auth_service_factory.dart';
import '../services/barber_service.dart';
import '../services/pelanggan_service.dart';
import '../utils/constants.dart';
import 'edit_profile_screen.dart';
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
    String _selectedFilter = 'Semua';
    String _sortBy = 'nama';
    bool _isDarkMode = false;
    bool _isScheduleTab = true;
    bool _isActiveBookingTab = true;
    bool _isSelectionMode = false;
  Set<int> _selectedScheduleIds = {};

    
 String? _getProfilePhotoUrl(String? photoPath) {
  if (photoPath == null || photoPath.isEmpty) return null;
  
  // Use Constants.buildProfilePhotoUrl for consistency
  return Constants.buildProfilePhotoUrl(photoPath);
}


    // Method untuk toggle dark mode
  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      // Simpan preferensi di SharedPreferences
      _saveDarkModePreference();
    });
    
    // Tampilkan snackbar konfirmasi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isDarkMode ? 'Dark mode aktif' : 'Light mode aktif')),
    );
  }

  // Method untuk menyimpan preferensi
  Future<void> _saveDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
  }

  // Method untuk mendapatkan preferensi saat startup
  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

    // Services
    final BarberService _barberService = BarberService();
    final PelangganService _pelangganService = PelangganService();

    // Data storage
    List<BarberSearch> _barbers = [];
    List<Booking> _bookings = [];
    Map<String, List<Schedule>> _schedules = {};
    Map<String, dynamic>? _stats;
    
    // Variables untuk penggajian (tambahkan setelah variable yang sudah ada)
List<Penggajian> _penggajianList = [];
PenggajianStats? _penggajianStats;
bool _isLoadingPenggajian = false;
String _selectedPenggajianFilter = 'semua'; // 'semua', 'belum_lunas', 'lunas'
int _currentPenggajianPage = 1;
bool _hasMorePenggajian = true;

    // UI State
    bool _isLoadingData = false;
    String _searchQuery = '';
    String _selectedDate = DateTime.now().toIso8601String().split('T')[0];
      bool _isActiveTab = true;

    @override
    void initState() {
      super.initState();
      _loadUserData();
      _loadDarkModePreference();
  }

 Future<void> _loadPenggajianData() async {
    try {
      setState(() => _isLoadingPenggajian = true);
      
      // Load stats
      final statsResult = await _barberService.getPenggajianStats();
      if (statsResult['success'] == true && statsResult['stats'] != null) {
        setState(() => _penggajianStats = PenggajianStats.fromJson(statsResult['stats']));
      }
      
      // Load penggajian list
      final penggajianResult = await _barberService.getPenggajian(
        status: _selectedPenggajianFilter == 'semua' ? null : _selectedPenggajianFilter,
        page: _currentPenggajianPage,
      );
      
      if (penggajianResult['success'] == true && penggajianResult['data'] != null) {
        final penggajianData = penggajianResult['data'] as List;
        setState(() {
          _penggajianList = penggajianData.map((item) => Penggajian.fromJson(item)).toList();
        });
        
        // Update pagination info
        if (penggajianResult['pagination'] != null) {
          setState(() {
            _hasMorePenggajian = penggajianResult['pagination']['has_more'] ?? false;
          });
        }
      }
      
    } catch (e) {
      print('Debug - Error loading penggajian data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading penggajian data: $e')),
      );
    } finally {
      setState(() => _isLoadingPenggajian = false);
    }
  }

  Widget _buildPenggajianPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Penggajian',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _loadPenggajianData,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stats cards
          if (_penggajianStats != null) ...[
            _buildPenggajianStats(),
            const SizedBox(height: 24),
          ],
          
          // Filter tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildFilterTab('semua', 'Semua'),
                _buildFilterTab('belum_lunas', 'Menanti'),
                _buildFilterTab('lunas', 'Dibayar'),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Content
          if (_isLoadingPenggajian)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_penggajianList.isEmpty)
            _buildEmptyPenggajianState()
          else
            Column(
              children: _penggajianList.map((penggajian) => _buildPenggajianCard(penggajian)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPenggajianStats() {
    if (_penggajianStats == null) return const SizedBox.shrink();
    
    return Column(
      children: [
        // Row pertama - gaji
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Gaji Menanti',
                _penggajianStats!.formattedTotalGajiMenanti,
                Icons.schedule,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Gaji Diterima',
                _penggajianStats!.formattedTotalGajiDiterima,
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row kedua - transaksi
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Transaksi Menanti',
                _penggajianStats!.jumlahTransaksiMenanti.toString(),
                Icons.pending,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Transaksi Selesai',
                _penggajianStats!.jumlahTransaksiSelesai.toString(),
                Icons.done_all,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterTab(String value, String label) {
    final isSelected = _selectedPenggajianFilter == value;
    
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          setState(() {
            _selectedPenggajianFilter = value;
            _currentPenggajianPage = 1;
          });
          await _loadPenggajianData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ] : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.black : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPenggajianState() {
    String message;
    String description;
    IconData icon;
    
    switch (_selectedPenggajianFilter) {
      case 'belum_lunas':
        message = 'Belum ada gaji menanti';
        description = 'Gaji yang belum dibayar akan muncul di sini';
        icon = Icons.schedule;
        break;
      case 'lunas':
        message = 'Belum ada gaji diterima';
        description = 'Riwayat gaji yang sudah dibayar akan muncul di sini';
        icon = Icons.check_circle;
        break;
      default:
        message = 'Belum ada data penggajian';
        description = 'Data penggajian akan muncul setelah ada transaksi yang selesai';
        icon = Icons.account_balance_wallet;
    }
    
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 32),
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPenggajianCard(Penggajian penggajian) {
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
          onTap: () => _showPenggajianDetails(penggajian),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header dengan status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        penggajian.namaPelanggan,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPenggajianStatusColor(penggajian.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        penggajian.isLunas ? 'Dibayar' : 'Menanti',
                        style: TextStyle(
                          color: _getPenggajianStatusColor(penggajian.status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Info tanggal
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Pesanan: ${penggajian.formattedTanggalPesanan}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Info jadwal jika ada
                if (penggajian.tanggalJadwal != null && penggajian.jamJadwal != null) ...[
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Jadwal: ${penggajian.formattedJadwalLengkap}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Info financial
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Bayar',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          penggajian.formattedTotalBayar,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Gaji Anda',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          penggajian.formattedTotalGaji,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Potongan jika ada
                if (penggajian.potongan > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.remove_circle_outline, size: 16, color: Colors.red[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Potongan: ${penggajian.formattedPotongan}',
                        style: TextStyle(
                          color: Colors.red[600],
                          fontSize: 12,
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

  Color _getPenggajianStatusColor(String status) {
    switch (status) {
      case 'lunas':
        return Colors.green;
      case 'belum lunas':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showPenggajianDetails(Penggajian penggajian) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PenggajianDetailsBottomSheet(
        penggajian: penggajian,
        barberService: _barberService,
      ),
    );
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
                final booking = Booking.fromJson(item);
                // Proses nama pelanggan sudah ada di fromJson
                processedBookings.add(booking);
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
      await _loadPenggajianData();

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
        sortBy: _sortBy, // Tambahkan parameter sort
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
                SnackBar(content: Text('Gagal menambahkan jadwal: $e')),
              );
            }
          },
        ),
      );
    }

  // Updated _addBulkTimeSlots method - place this in your main widget class
  Future<void> _addBulkTimeSlots() async {
    await showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing dialog accidentally
      builder: (context) => _BulkAddTimeSlotsDialog(
        onAddSlots: (slots) async {
          try {
            if (slots.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tidak ada jadwal yang ditambahkan')),
              );
              return;
            }
            
            // Show loading indicator
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 16),
                    Text('Menambahkan jadwal...'),
                  ],
                ),
                duration: Duration(seconds: 30), // Long duration for processing
              ),
            );
            
            // Use the bulkAddTimeSlots method from BarberService
            final result = await _barberService.bulkAddTimeSlots(slots);

            // Hide loading snackbar
            ScaffoldMessenger.of(context).hideCurrentSnackBar();

            if (result['success']) {
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'Jadwal berhasil ditambahkan'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
              
              // Refresh data to update UI
              await _loadBarberData();
              
              
              // Optional: Force rebuild of time slots if needed
              if (mounted) {
                setState(() {
                  // This will trigger a rebuild of the entire widget
                });
              }
              
            } else {
              throw Exception(result['message'] ?? 'Gagal menambahkan jadwal');
            }
          } catch (e) {
            // Hide loading snackbar
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
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
            SnackBar(content: Text('Gagal menghapus jadwal: $e')),
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
            _buildChatPage(), // Add chat page
             if (_userType == UserType.barber) _buildPenggajianPage(),
            _buildProfilePage(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildChatPage() {
    return const ChatListScreen();
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
      type: BottomNavigationBarType.fixed,
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
          icon: Icon(Icons.chat_bubble_outline),
          label: 'Chat',
        ),
        // Tambahkan tab Gaji khusus untuk barber
        if (_userType == UserType.barber)
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Gaji',
          ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
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
                     _selectedIndex = _userType == UserType.barber ? 4 : 3;
                  });
                },
                child: _buildProfileAvatar(), // Use new method
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Rest of your existing content...
          if (_isLoadingData)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            _userType == UserType.barber 
                ? _buildBarberDashboardContent() 
                : _buildPelangganDashboardContent(),
        ],
      ),
    );
  }

  // Method baru untuk membangun profile avatar
  Widget _buildProfileAvatar() {
  final photoPath = _userData is Barber 
      ? (_userData as Barber).profilePhoto 
      : (_userData as Pelanggan).profilePhoto;
      
  final photoUrl = _getProfilePhotoUrl(photoPath);
    
    return Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: Theme.of(context).primaryColor.withOpacity(0.3),
        width: 2,
      ),
    ),
    child: CircleAvatar(
      radius: 40,
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
      child: photoUrl != null 
          ? ClipOval(
              child: Image.network(
                photoUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  Constants.log('Error loading profile photo: $error');
                  Constants.log('Failed URL: $photoUrl');
                  
                  return Icon(
                    _userType == UserType.barber ? Icons.content_cut : Icons.person,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  );
                },
              ),
            )
          : Icon(
              _userType == UserType.barber ? Icons.content_cut : Icons.person,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
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
      
      // Tambahkan spesialisasi di sini
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.content_cut,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              (_userData as Barber).spesialisasi ?? 'Tidak ada spesialisasi',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
      const SizedBox(width: 12),
      Expanded(
        child: _buildStatCard(
          'Booking Bulan Ini',
          _stats!['total_bookings_this_month'].toString(),
          Icons.calendar_month,
          Colors.orange,
        ),
      ),
    ],
  ),
  const SizedBox(height: 24),
],
          // Quick access
          // Alternative layout with 3 buttons
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
              'Jadwal Cepat',  // New card for bulk scheduling
              Icons.calendar_month,
              Colors.teal,
              _addBulkTimeSlots,
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
                  _isScheduleTab = false;
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
              Row(
                children: [
                  if (_isSelectionMode && _selectedScheduleIds.isNotEmpty)
                    IconButton(
                      onPressed: _deleteSelectedSchedules,
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Hapus Terpilih',
                    ),
                  if (_isSelectionMode)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = false;
                          _selectedScheduleIds.clear();
                        });
                      },
                      child: const Text('Batal'),
                    ),
                  IconButton(
                    onPressed: _loadBarberData,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
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
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isScheduleTab = true;
                        _isSelectionMode = false;
                        _selectedScheduleIds.clear();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isScheduleTab ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _isScheduleTab ? [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: 5,
                            offset: const Offset(0, 1),
                          ),
                        ] : null,
                      ),
                      child: Center(
                        child: Text(
                          'Jadwal Saya',
                          style: TextStyle(
                            fontWeight: _isScheduleTab ? FontWeight.bold : FontWeight.normal,
                            color: _isScheduleTab ? Colors.black : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isScheduleTab = false;
                        _isSelectionMode = false;
                        _selectedScheduleIds.clear();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isScheduleTab ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: !_isScheduleTab ? [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: 5,
                            offset: const Offset(0, 1),
                          ),
                        ] : null,
                      ),
                      child: Center(
                        child: Text(
                          'Booking Masuk',
                          style: TextStyle(
                            fontWeight: !_isScheduleTab ? FontWeight.bold : FontWeight.normal,
                            color: !_isScheduleTab ? Colors.black : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          if (_isScheduleTab) 
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _getAvailableDatesUntilMonthEnd()
                        .map((dateInfo) => _buildDateCard(
                              dateInfo['day_short'],
                              dateInfo['day_number'],
                              dateInfo['date'] == _selectedDate,
                              () {
                                setState(() {
                                  _selectedDate = dateInfo['date'];
                                  _isSelectionMode = false;
                                  _selectedScheduleIds.clear();
                                });
                              },
                            ))
                        .toList(),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Time slots header with bulk actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Waktu Tersedia',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        if (todaysSchedules.isNotEmpty && !_isSelectionMode)
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _isSelectionMode = true;
                              });
                            },
                            icon: const Icon(Icons.checklist, size: 18),
                            label: const Text('Pilih'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.orange,
                            ),
                          ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _addTimeSlot,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Tambah'),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Selection mode info
                if (_isSelectionMode) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_selectedScheduleIds.length} jadwal dipilih. Tap jadwal untuk memilih/membatalkan pilihan.',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (_selectedScheduleIds.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedScheduleIds.clear();
                              });
                            },
                            child: const Text('Batal Semua'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue[700],
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Time slots grid
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
                      _buildSelectableTimeSlotChip(schedule)
                    ).toList(),
                  ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Booking tabs and content...
                // Keep existing booking content here
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isActiveBookingTab = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isActiveBookingTab ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _isActiveBookingTab ? [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 0,
                                  blurRadius: 5,
                                  offset: const Offset(0, 1),
                                ),
                              ] : null,
                            ),
                            child: Center(
                              child: Text(
                                'Sedang Berlangsung',
                                style: TextStyle(
                                  fontWeight: _isActiveBookingTab ? FontWeight.bold : FontWeight.normal,
                                  color: _isActiveBookingTab ? Colors.black : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isActiveBookingTab = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isActiveBookingTab ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: !_isActiveBookingTab ? [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 0,
                                  blurRadius: 5,
                                  offset: const Offset(0, 1),
                                ),
                              ] : null,
                            ),
                            child: Center(
                              child: Text(
                                'Selesai',
                                style: TextStyle(
                                  fontWeight: !_isActiveBookingTab ? FontWeight.bold : FontWeight.normal,
                                  color: !_isActiveBookingTab ? Colors.black : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                _buildFilteredBarberBookings(_isActiveBookingTab ? 'upcoming' : 'completed'),
              ],
            ),
        ],
      ),
    );
  }

  // Method baru untuk selectable time slot chip
  Widget _buildSelectableTimeSlotChip(Schedule schedule) {
    final isBooked = schedule.isBooked;
    final isSelected = _selectedScheduleIds.contains(schedule.id);
    
    return GestureDetector(
      onTap: () {
        if (_isSelectionMode && !isBooked) {
          setState(() {
            if (isSelected) {
              _selectedScheduleIds.remove(schedule.id);
            } else {
              _selectedScheduleIds.add(schedule.id);
            }
          });
        }
      },
      onLongPress: !isBooked ? () => _deleteTimeSlot(schedule) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.red.withOpacity(0.2)
              : isBooked 
                  ? Colors.grey[200] 
                  : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.red
                : isBooked 
                    ? Colors.grey[300]! 
                    : Theme.of(context).primaryColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Text(
                  schedule.jam,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.red[700]
                        : isBooked 
                            ? Colors.grey[500] 
                            : Colors.black,
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
            if (_isSelectionMode && !isBooked)
              Positioned(
                top: -8,
                right: -8,
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? Colors.red : Colors.grey[400],
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Method untuk menghapus jadwal yang dipilih
  Future<void> _deleteSelectedSchedules() async {
    if (_selectedScheduleIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jadwal Terpilih'),
        content: Text(
          'Apakah Anda yakin ingin menghapus ${_selectedScheduleIds.length} jadwal yang dipilih?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Show loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Menghapus jadwal...'),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );
        
        final result = await _barberService.deleteMultipleTimeSlots(_selectedScheduleIds.toList());

        // Hide loading
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (result['success'] != false) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_selectedScheduleIds.length} jadwal berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          
          setState(() {
            _isSelectionMode = false;
            _selectedScheduleIds.clear();
          });
          
          await _loadBarberData(); // Refresh data
        } else {
          throw Exception(result['message'] ?? 'Gagal menghapus jadwal');
        }
      } catch (e) {
        // Hide loading
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Tambahkan helper method ini setelah _buildBarberBookingsPage()
  Widget _buildFilteredBarberBookings(String status) {
    final filteredBookings = _bookings.where((booking) => booking.status == status).toList();
    
    if (filteredBookings.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 32),
            Icon(
              status == 'upcoming' ? Icons.calendar_today : Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              status == 'upcoming' 
                  ? 'Belum ada booking mendatang' 
                  : 'Belum ada booking selesai',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              status == 'upcoming'
                  ? 'Booking baru akan muncul di sini'
                  : 'Riwayat booking selesai akan muncul di sini',
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: filteredBookings.map((booking) => _buildBarberBookingCard(booking)).toList(),
    );
  }

  List<Schedule> get todaysSchedules {
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate as DateTime);
    return _schedules[dateKey] ?? [];
  }

  // Method helper untuk mendapatkan tanggal hingga akhir bulan
  List<Map<String, dynamic>> _getAvailableDatesUntilMonthEnd() {
    final List<Map<String, dynamic>> dates = [];
    final now = DateTime.now();
    
    // Tanggal terakhir bulan ini
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysUntilMonthEnd = lastDayOfMonth.difference(now).inDays + 1;
    
    for (int i = 0; i < daysUntilMonthEnd; i++) {
      final date = now.add(Duration(days: i));
      dates.add({
        'date': date.toIso8601String().split('T')[0],
        'day_short': _getDayShort(date.weekday),
        'day_number': date.day.toString(),
        'is_selected': i == 0, // Default hari pertama yang dipilih
      });
    }
    
    return dates;
  }

  // Helper method untuk mendapatkan nama hari singkat
  String _getDayShort(int weekday) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[(weekday - 1) % 7]; // Handle index 0-6
  }

  // Implementasi widget card untuk booking yang masuk
  Widget _buildBarberBookingCard(Booking booking) {
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.bookingDetails.alamatLengkap ?? 'Lokasi tidak tersedia',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    booking.schedule.formattedDate ?? booking.schedule.date,
                    style: const TextStyle(
                      color: Colors.blue,
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
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Pelanggan: ${booking.pelangganNama}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                  'Waktu: ${booking.schedule.time}',
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
                Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Telepon: ${booking.bookingDetails.telepon ?? 'Tidak tersedia'}',
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
            
            // Buttons for actions
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Chat button
  OutlinedButton.icon(
    onPressed: () {
      // Navigasi chat belum diimplementasikan
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fitur chat belum tersedia')),
      );
    },
    icon: const Icon(Icons.chat_bubble_outline, size: 16),
    label: const Text('Chat'),
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.blue,
      side: const BorderSide(color: Colors.blue),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      minimumSize: const Size(0, 32),
    ),
  ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    // Implementasi untuk menghubungi pelanggan
                    if (booking.bookingDetails.telepon != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Menghubungi ${booking.bookingDetails.telepon}')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nomor telepon tidak tersedia')),
                      );
                    }
                  },
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Hubungi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    minimumSize: const Size(0, 32),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    // Show booking details in a modal
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => _BookingDetailsBottomSheet(
                        booking: booking,
                        onCancel: null, // Barber cannot cancel bookings
                      ),
                    );
                  },
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('Detail'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ],
            ),
          ],
        ),
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
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isActiveTab = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isActiveTab ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _isActiveTab ? [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: 5,
                            offset: const Offset(0, 1),
                          ),
                        ] : null,
                      ),
                      child: Center(
                        child: Text(
                          'Aktif (${activeBookings.length})',
                          style: TextStyle(
                            fontWeight: _isActiveTab ? FontWeight.bold : FontWeight.normal,
                            color: _isActiveTab ? Colors.black : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isActiveTab = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isActiveTab ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: !_isActiveTab ? [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: 5,
                            offset: const Offset(0, 1),
                          ),
                        ] : null,
                      ),
                      child: Center(
                        child: Text(
                          'Riwayat (${historyBookings.length})',
                          style: TextStyle(
                            fontWeight: !_isActiveTab ? FontWeight.bold : FontWeight.normal,
                            color: !_isActiveTab ? Colors.black : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Content based on selected tab - use proper conditional widget pattern
          _isActiveTab
              ? _buildActiveBookingsContent(activeBookings)
              : _buildHistoryBookingsContent(historyBookings),
        ],
      ),
    );
  }

  // Helper method for active bookings content
  Widget _buildActiveBookingsContent(List<Booking> activeBookings) {
    if (activeBookings.isEmpty) {
      return Center(
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
      );
    } else {
      return Column(
        children: activeBookings.map((booking) => _buildBookingCard(booking)).toList(),
      );
    }
  }

  // Helper method for history bookings content
  Widget _buildHistoryBookingsContent(List<Booking> historyBookings) {
    if (historyBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada riwayat booking',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Booking yang telah selesai akan muncul di sini',
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedIndex = 0; // Go to home to book new
                });
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cari Barber Baru',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Column(
        children: historyBookings.map((booking) => _buildBookingCard(booking)).toList(),
      );
    }
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
                // Profile picture with photo
                _buildProfilePictureSection(),
                
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
                
                // Role badge
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
                
                // Rest of profile information...
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
          
          // Rest of your existing profile content...
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

  // Method baru untuk profile picture section
 Widget _buildProfilePictureSection() {
  final photoPath = _userData is Barber 
      ? (_userData as Barber).profilePhoto 
      : (_userData as Pelanggan).profilePhoto;
      
  final photoUrl = _getProfilePhotoUrl(photoPath);
  
  return Stack(
    children: [
      Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            width: 3,
          ),
        ),
        child: CircleAvatar(
          radius: 48,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
          child: photoUrl != null 
              ? ClipOval(
                  child: Image.network(
                    photoUrl,
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return SizedBox(
                        width: 96,
                        height: 96,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      Constants.log('Error loading profile photo: $error');
                      Constants.log('Failed URL: $photoUrl');
                      
                      return Icon(
                        _userType == UserType.barber ? Icons.content_cut : Icons.person,
                        size: 48,
                        color: Theme.of(context).primaryColor,
                      );
                    },
                  ),
                )
              : Icon(
                  _userType == UserType.barber ? Icons.content_cut : Icons.person,
                  size: 48,
                  color: Theme.of(context).primaryColor,
                ),
        ),
      ),
      ],
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
                child: barber.profilePhoto != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _getProfilePhotoUrl(barber.profilePhoto) ?? '',
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('Debug - Error loading barber photo: $error');
                            print('Debug - Failed URL: ${_getProfilePhotoUrl(barber.profilePhoto)}');
                            return Icon(
                              Icons.content_cut,
                              size: 32,
                              color: Theme.of(context).primaryColor,
                            );
                          },
                        ),
                      )
                    : Icon(
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tombol Chat
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: () => _navigateToDirectChat(barber),
                          icon: const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.blue,
                            size: 20,
                          ),
                          tooltip: 'Chat',
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Tombol Lihat
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
            ],
          ),
        ),
      ),
    ),
  );
}

  // Method baru untuk navigasi ke direct chat
 void _navigateToDirectChat(BarberSearch barber) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DirectChatScreen(
        userId: barber.id,
        userName: barber.nama,
        userPhoto: barber.profilePhoto,
        userSpesialisasi: barber.spesialisasi,
        userType: 'barber', // Explicitly specify that this is a barber
      ),
    ),
  ).then((_) {
    // Refresh chat list when returning from chat
    if (_selectedIndex == 2) { // If on chat tab
      setState(() {
        // Trigger a refresh of the chat list screen
      });
    }
  });
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
                
                // Payment status
                if (booking.bookingDetails.statusPembayaran != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        booking.bookingDetails.statusPembayaran == 'paid' 
                            ? Icons.check_circle 
                            : Icons.pending,
                        size: 16,
                        color: booking.bookingDetails.statusPembayaran == 'paid'
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        booking.bookingDetails.statusPembayaran == 'paid'
                            ? 'Sudah Dibayar'
                            : 'Belum Dibayar',
                        style: TextStyle(
                          color: booking.bookingDetails.statusPembayaran == 'paid'
                              ? Colors.green
                              : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
                
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
                
                // Action buttons
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Payment button (only if not paid and status is upcoming)
                    if (booking.status == 'upcoming' && 
                        (booking.bookingDetails.statusPembayaran == null || 
                        booking.bookingDetails.statusPembayaran != 'paid')) ...[
                      OutlinedButton.icon(
                        onPressed: () => _navigateToPayment(booking),
                        icon: const Icon(Icons.payment, size: 16),
                        label: const Text('Bayar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          minimumSize: const Size(0, 32),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    
                    // Chat button (only if paid)
  if (booking.bookingDetails.statusPembayaran == 'paid') ...[
    OutlinedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fitur chat belum tersedia')),
        );
      },
      icon: const Icon(Icons.chat_bubble_outline, size: 16),
      label: const Text('Chat'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue,
        side: const BorderSide(color: Colors.blue),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        minimumSize: const Size(0, 32),
      ),
    ),
    const SizedBox(width: 8),
  ],
                    
                    // Cancel button
                    if (booking.canCancel) ...[
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
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToPayment(Booking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(booking: booking),
      ),
    ).then((result) {
      if (result == true) {
        // Payment was created, refresh bookings
        _loadPelangganData();
      }
    });
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
    String sortValue = 'nama'; // default

  // Map label ke nilai sortBy yang sesuai dengan API
    if (label == 'Rating Tertinggi') {
      sortValue = 'rating_desc';
    } else if (label == 'Harga Terendah') {
      sortValue = 'harga_asc';
    } else if (label == 'Terdekat') {
      sortValue = 'distance'; // Anda perlu menambahkan ini di API
    } else {
      sortValue = 'nama'; // Default untuk "Semua"
    }

      return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) {
            setState(() {
              _selectedFilter = label;
              _sortBy = sortValue;
            });
            
            // Reload barbers dengan filter baru
            _searchBarbers(_searchQuery);
          }
        },
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
        ongkosKirim: 10000,
      );

      if (result['success']) {
        Navigator.pop(context);
        
        final bookingData = result['booking'];
        
        // Show success dialog with payment option
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Booking Berhasil!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Booking Anda dengan ${widget.barber.nama} telah dibuat.'),
                const SizedBox(height: 8),
                Text('ID Transaksi: ${bookingData['id_transaksi']}'),
                const SizedBox(height: 8),
                Text('Total: ${bookingData['total_amount'] != null ? 
                  'Rp ${bookingData['total_amount'].toStringAsFixed(0)}' : ""}'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Silakan lakukan pembayaran untuk mengkonfirmasi booking Anda.',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onBookingSuccess();
                },
                child: const Text('Nanti'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to payment screen
                  // You'll need to create a Booking object from bookingData
                  // and navigate to PaymentScreen
                  widget.onBookingSuccess();
                },
                child: const Text('Bayar Sekarang'),
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


  // Tambahkan kelas ini di bagian paling bawah file, setelah semua kelas widget lainnya
  class _BulkAddTimeSlotsDialog extends StatefulWidget {
    final Function(List<Map<String, String>>) onAddSlots;

    const _BulkAddTimeSlotsDialog({required this.onAddSlots});

    @override
    State<_BulkAddTimeSlotsDialog> createState() => __BulkAddTimeSlotsDialogState();
  }

  class __BulkAddTimeSlotsDialogState extends State<_BulkAddTimeSlotsDialog> {
    DateTime _startDate = DateTime.now();
    DateTime _endDate = DateTime.now().add(const Duration(days: 7));
    final List<TimeOfDay> _selectedTimes = [];
    final List<int> _selectedDays = [1, 2, 3, 4, 5]; // Monday to Friday by default
    
    final List<String> _daysOfWeek = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    
    bool _isLoading = false;

    @override
    Widget build(BuildContext context) {
      return AlertDialog(
        title: const Text('Jadwal Cepat'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Start date picker
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Tanggal Mulai'),
                subtitle: Text(
                  '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date != null) {
                    setState(() {
                      _startDate = date;
                      // Ensure end date is not before start date
                      if (_endDate.isBefore(_startDate)) {
                        _endDate = _startDate.add(const Duration(days: 7));
                      }
                    });
                  }
                },
              ),
              
              // End date picker
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Tanggal Akhir'),
                subtitle: Text(
                  '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate,
                    firstDate: _startDate,
                    lastDate: _startDate.add(const Duration(days: 30)),
                  );
                  if (date != null) {
                    setState(() => _endDate = date);
                  }
                },
              ),
              
              const SizedBox(height: 16),
              
              // Days of week selection
              const Text(
                'Pilih Hari',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (index) {
                  final dayNumber = index + 1; // 1=Monday, 7=Sunday
                  final isSelected = _selectedDays.contains(dayNumber);
                  
                  return FilterChip(
                    label: Text(_daysOfWeek[index]),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(dayNumber);
                        } else {
                          _selectedDays.remove(dayNumber);
                        }
                      });
                    },
                  );
                }),
              ),
              
              const SizedBox(height: 16),
              
              // Time slots section
              const Text(
                'Pilih Waktu',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              
              // Quick times buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickTimeButton('08:00'),
                  _buildQuickTimeButton('09:00'),
                  _buildQuickTimeButton('10:00'),
                  _buildQuickTimeButton('11:00'),
                  _buildQuickTimeButton('13:00'),
                  _buildQuickTimeButton('14:00'),
                  _buildQuickTimeButton('15:00'),
                  _buildQuickTimeButton('16:00'),
                  _buildQuickTimeButton('17:00'),
                  _buildQuickTimeButton('18:00'),
                  _buildQuickTimeButton('19:00'),
                  ElevatedButton.icon(
                    onPressed: _addCustomTime,
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              
              if (_selectedTimes.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Waktu dipilih:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedTimes.map((time) {
                    return Chip(
                      label: Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedTimes.remove(time);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Preview section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preview:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dari ${_startDate.day}/${_startDate.month} sampai ${_endDate.day}/${_endDate.month}',
                    ),
                    Text(
                      'Hari: ${_selectedDays.map((d) => _daysOfWeek[d-1]).join(', ')}',
                    ),
                    Text(
                      'Waktu: ${_selectedTimes.map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}').join(', ')}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total ${_calculateTotalSlots()} slot waktu',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _generateAndAddSlots,
            child: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Tambah Jadwal'),
          ),
        ],
      );
    }

    Widget _buildQuickTimeButton(String time) {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts.length > 1 ? int.parse(parts[1]) : 0;
      final timeOfDay = TimeOfDay(hour: hour, minute: minute);
      
      final isSelected = _selectedTimes.any((t) => t.hour == hour && t.minute == minute);
      
      return FilterChip(
        label: Text(time),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            if (selected) {
              _selectedTimes.add(timeOfDay);
            } else {
              _selectedTimes.removeWhere((t) => t.hour == hour && t.minute == minute);
            }
          });
        },
      );
    }

    Future<void> _addCustomTime() async {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      
      if (time != null) {
        setState(() {
          // Check if time already exists
          if (!_selectedTimes.any((t) => t.hour == time.hour && t.minute == time.minute)) {
            _selectedTimes.add(time);
          }
        });
      }
    }

    int _calculateTotalSlots() {
      if (_selectedTimes.isEmpty || _selectedDays.isEmpty) return 0;
      
      final totalDays = _endDate.difference(_startDate).inDays + 1;
      int totalSlots = 0;
      
      for (int i = 0; i < totalDays; i++) {
        final date = _startDate.add(Duration(days: i));
        if (_selectedDays.contains(date.weekday)) {
          totalSlots += _selectedTimes.length;
        }
      }
      
      return totalSlots;
    }

    void _generateAndAddSlots() {
      if (_selectedTimes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih minimal satu waktu')),
        );
        return;
      }
      
      if (_selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih minimal satu hari')),
        );
        return;
      }
      
      final List<Map<String, String>> slots = [];
      
      final totalDays = _endDate.difference(_startDate).inDays + 1;
      
      for (int i = 0; i < totalDays; i++) {
        final date = _startDate.add(Duration(days: i));
        
        if (_selectedDays.contains(date.weekday)) {
          for (final time in _selectedTimes) {
            slots.add({
              'tanggal': date.toIso8601String().split('T')[0],
              'jam': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
            });
          }
        }
      }
      
      Navigator.pop(context);
      widget.onAddSlots(slots);
    }
  }

  class _PenggajianDetailsBottomSheet extends StatefulWidget {
  final Penggajian penggajian;
  final BarberService barberService;

  const _PenggajianDetailsBottomSheet({
    required this.penggajian,
    required this.barberService,
  });

  @override
  State<_PenggajianDetailsBottomSheet> createState() => __PenggajianDetailsBottomSheetState();
}

class __PenggajianDetailsBottomSheetState extends State<_PenggajianDetailsBottomSheet> {
  Map<String, dynamic>? _detailData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final result = await widget.barberService.getPenggajianDetail(widget.penggajian.idGaji);
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _detailData = result['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading detail: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
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
                            'Detail Penggajian',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            'ID: ${widget.penggajian.idGaji}',
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
                        color: _getStatusColor(widget.penggajian.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.penggajian.isLunas ? 'Sudah Dibayar' : 'Menanti Pembayaran',
                        style: TextStyle(
                          color: _getStatusColor(widget.penggajian.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  // Info Pelanggan
                  _buildInfoSection(
                    'Informasi Pelanggan',
                    [
                      _buildInfoRow(Icons.person, 'Nama', widget.penggajian.namaPelanggan),
                      _buildInfoRow(Icons.tag, 'ID Pelanggan', '#${widget.penggajian.idPelanggan}'),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Info Pesanan
                  _buildInfoSection(
                    'Informasi Pesanan',
                    [
                      _buildInfoRow(Icons.receipt, 'ID Pesanan', '#${widget.penggajian.idPesanan}'),
                      _buildInfoRow(Icons.calendar_today, 'Tanggal Pesanan', widget.penggajian.formattedTanggalPesanan),
                      if (widget.penggajian.tanggalJadwal != null && widget.penggajian.jamJadwal != null)
                        _buildInfoRow(Icons.schedule, 'Jadwal Layanan', widget.penggajian.formattedJadwalLengkap),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Info Keuangan
                  _buildInfoSection(
                    'Rincian Keuangan',
                    [
                      _buildInfoRow(Icons.attach_money, 'Total Pembayaran', widget.penggajian.formattedTotalBayar),
                      if (widget.penggajian.potongan > 0)
                        _buildInfoRow(Icons.remove_circle, 'Potongan', widget.penggajian.formattedPotongan, 
                            isNegative: true),
                      _buildInfoRow(Icons.account_balance_wallet, 'Gaji Anda', widget.penggajian.formattedTotalGaji,
                          isHighlight: true),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Info Rekening
                  if (widget.penggajian.rekeningBarber.isNotEmpty) ...[
                    _buildInfoSection(
                      'Informasi Rekening',
                      [
                        _buildInfoRow(Icons.account_balance, 'Rekening Tujuan', widget.penggajian.rekeningBarber),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                  
                  // Bukti Transfer (jika ada)
                  if (widget.penggajian.buktiTransfer != null && widget.penggajian.buktiTransfer!.isNotEmpty) ...[
                    _buildInfoSection(
                      'Bukti Transfer',
                      [
                        _buildBuktiTransferSection(),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                  
                  // Status dan Waktu
                  _buildInfoSection(
                    'Status Pembayaran',
                    [
                      _buildInfoRow(Icons.info, 'Status', 
                          widget.penggajian.isLunas ? 'Sudah Dibayar' : 'Menanti Pembayaran'),
                      if (widget.penggajian.createdAt != null)
                        _buildInfoRow(Icons.access_time, 'Dibuat', 
                            _formatDateTime(widget.penggajian.createdAt!)),
                      if (widget.penggajian.updatedAt != null && widget.penggajian.isLunas)
                        _buildInfoRow(Icons.check_circle, 'Dibayar', 
                            _formatDateTime(widget.penggajian.updatedAt!)),
                    ],
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Action button untuk refresh
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Callback untuk refresh data di parent
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tutup'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isNegative = false, bool isHighlight = false}) {
    Color? valueColor;
    if (isNegative) valueColor = Colors.red[600];
    if (isHighlight) valueColor = Theme.of(context).primaryColor;
    
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
                  style: TextStyle(
                    fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                    fontSize: isHighlight ? 16 : 14,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuktiTransferSection() {
    if (_detailData?['bukti_transfer_url'] == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(Icons.image, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Bukti transfer tidak tersedia',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.image, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 12),
              const Text(
                'Bukti Transfer',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _detailData!['bukti_transfer_url'],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[100],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.grey[400], size: 48),
                        const SizedBox(height: 8),
                        Text(
                          'Gagal memuat gambar',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _showFullscreenImage(_detailData!['bukti_transfer_url']);
              },
              icon: const Icon(Icons.fullscreen, size: 16),
              label: const Text('Lihat Ukuran Penuh'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullscreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Bukti Transfer',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.white, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'Gagal memuat gambar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'lunas':
        return Colors.green;
      case 'belum lunas':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    
    final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year} • $time';
  }
}