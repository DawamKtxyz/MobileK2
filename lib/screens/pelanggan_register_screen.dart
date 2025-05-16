import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/pelanggan_auth_service.dart';
import '../widgets/custom_text_field.dart';
import 'login_screen.dart';

class PelangganRegisterScreen extends StatefulWidget {
  const PelangganRegisterScreen({Key? key}) : super(key: key);

  @override
  State<PelangganRegisterScreen> createState() => _PelangganRegisterScreenState();
}

class _PelangganRegisterScreenState extends State<PelangganRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  final _teleponController = TextEditingController();
  final _alamatController = TextEditingController();
  
  final _pelangganAuthService = PelangganAuthService();
  
  DateTime? _selectedDate;
  bool _isLoading = false;

  // Function to show date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Format date for display
  String get _formattedDate {
    if (_selectedDate == null) return 'Pilih Tanggal Lahir';
    return DateFormat('dd-MM-yyyy').format(_selectedDate!);
  }

  // Register function
  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      // Check password confirmation
      if (_passwordController.text != _passwordConfirmationController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password dan konfirmasi password tidak cocok'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      setState(() => _isLoading = true);
      
      try {
        // Create data map
        final data = {
          'nama': _namaController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'telepon': _teleponController.text,
          'alamat': _alamatController.text,
          'tanggal_lahir': _selectedDate != null 
              ? DateFormat('yyyy-MM-dd').format(_selectedDate!) 
              : null,
        };
        
        final success = await _pelangganAuthService.register(data);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registrasi berhasil! Silakan login.'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate back to login screen
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrasi Pelanggan'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Daftar Akun Pelanggan',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Nama
                CustomTextField(
                  controller: _namaController,
                  label: 'Nama Lengkap',
                  keyboardType: TextInputType.name,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                
                // Email
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    if (!value.contains('@')) {
                      return 'Email tidak valid';
                    }
                    return null;
                  },
                ),
                
                // Telepon
                CustomTextField(
                  controller: _teleponController,
                  label: 'Nomor Telepon',
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nomor telepon tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                
                // Alamat
                CustomTextField(
                  controller: _alamatController,
                  label: 'Alamat',
                  keyboardType: TextInputType.streetAddress,
                  // Note: If CustomTextField doesn't support maxLines, you can use a regular TextField instead
                  // or modify your CustomTextField to include this parameter
                ),
                
                // Tanggal Lahir
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formattedDate,
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedDate == null 
                                  ? Colors.grey[600] 
                                  : Colors.black,
                            ),
                          ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Password
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    if (value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                
                // Password Confirmation
                CustomTextField(
                  controller: _passwordConfirmationController,
                  label: 'Konfirmasi Password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Konfirmasi password tidak boleh kosong';
                    }
                    if (value != _passwordController.text) {
                      return 'Password tidak cocok';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Register Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'Daftar',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Login Link
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Sudah punya akun? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    _teleponController.dispose();
    _alamatController.dispose();
    super.dispose();
  }
}