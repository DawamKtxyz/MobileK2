// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _teleponController = TextEditingController();
  final _spesialisasiController = TextEditingController();
  final _hargaController = TextEditingController();
  final _namaBankController = TextEditingController();      // Tambahan untuk nama bank
  final _rekeningController = TextEditingController();      // Tambahan untuk nomor rekening
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  PlatformFile? _selectedFile;

  // List bank populer di Indonesia
  final List<String> _bankList = [
    'BCA',
    'BRI',
    'BNI',
    'Mandiri',
    'CIMB Niaga',
    'BTN',
    'Danamon',
    'Permata',
    'Maybank',
    'OCBC NISP',
    'BSI (Bank Syariah Indonesia)',
    'Jenius',
    'Digibank',
    'Lainnya'
  ];

  String? _selectedBank;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan upload sertifikat PDF')),
      );
      return;
    }

    if (_selectedFile!.size > 2 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ukuran file maksimal 2MB')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final registrationData = {
        'nama': _namaController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'telepon': _teleponController.text,
        'spesialisasi': _spesialisasiController.text.isEmpty
            ? ''
            : _spesialisasiController.text,
        'harga': _hargaController.text.isEmpty
            ? '20000'
            : _hargaController.text.replaceAll(RegExp(r'[^\d]'), ''),
        'nama_bank': _selectedBank == 'Lainnya' 
            ? _namaBankController.text 
            : (_selectedBank ?? ''),                    // Tambahan nama bank
        'rekening_barber': _rekeningController.text,    // Tambahan nomor rekening
      };

      final success = await _authService.register(
        registrationData,
        file: _selectedFile,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi berhasil! Silakan login.')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi gagal. Coba lagi.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrasi Barber'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.content_cut,
                      size: 64,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Daftar Sebagai Barber',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bergabunglah dengan komunitas BarberGo',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Form fields
              TextFormField(
                controller: _namaController,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  hintText: 'Masukkan nama lengkap Anda',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty 
                    ? 'Nama tidak boleh kosong' 
                    : null,
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Masukkan email Anda',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Masukkan password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword 
                        ? Icons.visibility_off 
                        : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _teleponController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Nomor Telepon',
                  hintText: 'Masukkan nomor telepon',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty 
                    ? 'Nomor telepon tidak boleh kosong' 
                    : null,
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _spesialisasiController,
                decoration: InputDecoration(
                  labelText: 'Spesialisasi',
                  hintText: 'Contoh: Burst Fade, Pompadour, dll',
                  prefixIcon: const Icon(Icons.design_services),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _hargaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Harga (Rp)',
                  hintText: 'Masukkan harga layanan',
                  prefixIcon: const Icon(Icons.attach_money),
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Bank Information Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue[200]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Informasi Bank',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Digunakan untuk penerimaan pembayaran dari admin',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Bank Selection Dropdown
              DropdownButtonFormField<String>(
                value: _selectedBank,
                decoration: InputDecoration(
                  labelText: 'Pilih Bank',
                  hintText: 'Pilih bank Anda',
                  prefixIcon: const Icon(Icons.account_balance),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _bankList.map((String bank) {
                  return DropdownMenuItem<String>(
                    value: bank,
                    child: Text(bank),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedBank = newValue;
                  });
                },
                validator: (value) => value == null 
                    ? 'Silakan pilih bank' 
                    : null,
              ),
              
              const SizedBox(height: 16),
              
              // Custom bank name field (shown only when "Lainnya" is selected)
              if (_selectedBank == 'Lainnya')
                Column(
                  children: [
                    TextFormField(
                      controller: _namaBankController,
                      decoration: InputDecoration(
                        labelText: 'Nama Bank',
                        hintText: 'Masukkan nama bank',
                        prefixIcon: const Icon(Icons.business),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (_selectedBank == 'Lainnya' && (value == null || value.isEmpty)) {
                          return 'Nama bank tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              
              // Account Number Field
              TextFormField(
                controller: _rekeningController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nomor Rekening',
                  hintText: 'Masukkan nomor rekening',
                  prefixIcon: const Icon(Icons.credit_card),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty 
                    ? 'Nomor rekening tidak boleh kosong' 
                    : null,
              ),
              
              const SizedBox(height: 24),
              
              // Certificate Upload Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange[200]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.upload_file,
                          color: Colors.orange[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Upload Sertifikat',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload sertifikat barber dalam format PDF (Maksimal 2MB)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // File picker button
              InkWell(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedFile != null 
                          ? Colors.green 
                          : Colors.grey[300]!,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _selectedFile != null 
                        ? Colors.green[50] 
                        : Colors.grey[50],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile != null 
                            ? Icons.check_circle 
                            : Icons.cloud_upload_outlined,
                        size: 48,
                        color: _selectedFile != null 
                            ? Colors.green 
                            : Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFile != null 
                            ? 'File terpilih: ${_selectedFile!.name}'
                            : 'Tap untuk memilih file PDF',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedFile != null 
                              ? Colors.green[700] 
                              : Colors.grey[600],
                          fontWeight: _selectedFile != null 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Register button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Daftar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Login navigation
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sudah punya akun? ',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    _teleponController.dispose();
    _spesialisasiController.dispose();
    _hargaController.dispose();
    _namaBankController.dispose();
    _rekeningController.dispose();
    super.dispose();
  }
}