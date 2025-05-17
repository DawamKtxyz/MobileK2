// lib/screens/barber_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/barber_model.dart';

class BarberDetailScreen extends StatefulWidget {
  final Barber barber;
  
  const BarberDetailScreen({
    Key? key,
    required this.barber,
  }) : super(key: key);

  @override
  State<BarberDetailScreen> createState() => _BarberDetailScreenState();
}

class _BarberDetailScreenState extends State<BarberDetailScreen> {
  DateTime? _selectedDate;
  String? _selectedTime;
  
  final List<String> _timeSlots = [
    '08:00', '09:00', '10:00', '11:00', 
    '13:00', '14:00', '15:00', '16:00', '17:00'
  ];
  
  // Mock data for available dates
  final List<DateTime> _availableDates = List.generate(
    7, 
    (index) => DateTime.now().add(Duration(days: index))
  );
  
  @override
  void initState() {
    super.initState();
    // Set the default selected date to today
    _selectedDate = _availableDates.first;
  }
  
  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedTime = null; // Reset selected time when date changes
    });
  }
  
  void _selectTime(String time) {
    setState(() {
      _selectedTime = time;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with barber profile
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.barber.nama,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).primaryColor,
                          const Color(0xFF2563EB),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.content_cut,
                      size: 72,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Barber details
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barber info card
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                                child: Icon(
                                  Icons.person,
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
                                      widget.barber.nama,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          '4.8',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '(124 reviews)',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Tersedia',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const Divider(height: 32),
                          
                          // Specialization
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.design_services,
                                  size: 20,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Spesialisasi',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.barber.spesialisasi ?? 'Semua jenis potongan',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Price
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.attach_money,
                                  size: 20,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Harga',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rp ${widget.barber.harga}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Booking section
                    const Text(
                      'Pilih Tanggal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Date selection
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _availableDates.length,
                        itemBuilder: (context, index) {
                          final date = _availableDates[index];
                          final isSelected = _selectedDate?.day == date.day &&
                              _selectedDate?.month == date.month &&
                              _selectedDate?.year == date.year;
                          
                          return GestureDetector(
                            onTap: () => _selectDate(date),
                            child: Container(
                              width: 70,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Theme.of(context).primaryColor 
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected 
                                      ? Theme.of(context).primaryColor 
                                      : Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'][date.weekday % 7],
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    date.day.toString(),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'][date.month - 1],
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Time selection
                    const Text(
                      'Pilih Waktu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _timeSlots.map((time) {
                        final isSelected = _selectedTime == time;
                        // Mock some times as booked
                        final isBooked = time == '09:00' || time == '15:00';
                        
                        return GestureDetector(
                          onTap: isBooked ? null : () => _selectTime(time),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isBooked 
                                  ? Colors.grey[200] 
                                  : isSelected 
                                      ? Theme.of(context).primaryColor 
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isBooked 
                                    ? Colors.grey[300]! 
                                    : isSelected 
                                        ? Theme.of(context).primaryColor 
                                        : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              time,
                              style: TextStyle(
                                color: isBooked 
                                    ? Colors.grey[500] 
                                    : isSelected 
                                        ? Colors.white 
                                        : Colors.grey[800],
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                decoration: isBooked ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Booking button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedTime == null 
                            ? null 
                            : () {
                                _showBookingConfirmation(context);
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Booking Sekarang',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Booking note
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Pembayaran akan dilakukan setelah pelayanan selesai.',
                              style: TextStyle(
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Reviews section
                    const Text(
                      'Ulasan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Review cards
                    _buildReviewCard(
                      'Ahmad Farhan',
                      5,
                      'Sangat puas dengan hasil potongnya, rapih dan sesuai keinginan!',
                      '2 hari yang lalu',
                    ),
                    _buildReviewCard(
                      'Budi Santoso',
                      4,
                      'Pelayanan bagus, tapi agak lama menunggu.',
                      '1 minggu yang lalu',
                    ),
                    _buildReviewCard(
                      'Rudi Hermawan',
                      5,
                      'Kualitas potong premium dengan harga terjangkau. Recommended!',
                      '2 minggu yang lalu',
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
    String name,
    int rating,
    String comment,
    String date,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // User info
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[200],
                    child: Text(
                      name[0],
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              // Date
              Text(
                date,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Rating stars
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 16,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Comment
          Text(comment),
        ],
      ),
    );
  }

  void _showBookingConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Barber: ${widget.barber.nama}'),
            const SizedBox(height: 8),
            Text(
              'Tanggal: ${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}',
            ),
            const SizedBox(height: 8),
            Text('Waktu: $_selectedTime WIB'),
            const SizedBox(height: 8),
            Text('Harga: Rp ${widget.barber.harga}'),
            const SizedBox(height: 16),
            const Text(
              'Apakah data booking sudah benar?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Process booking
              Navigator.of(context).pop();
              _showBookingSuccess(context);
            },
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
  }

  void _showBookingSuccess(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Booking Berhasil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Booking Anda telah berhasil dibuat!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda dapat melihat detail booking di halaman Booking Saya.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to previous screen
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Lihat Booking Saya'),
            ),
          ),
        ],
      ),
    );
  }
}