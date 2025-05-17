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
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  PlatformFile? _selectedFile;

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
              
              // Certificate upload
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sertifikat Barber',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Upload sertifikat Anda dalam format PDF (maks. 2MB)',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickFile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedFile != null 
                              ? Theme.of(context).primaryColor.withOpacity(0.1) 
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedFile != null 
                                ? Theme.of(context).primaryColor 
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedFile != null 
                                  ? Icons.check_circle 
                                  : Icons.upload_file,
                              color: _selectedFile != null 
                                  ? Theme.of(context).primaryColor 
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedFile != null
                                  ? _selectedFile!.name
                                  : 'Pilih File',
                              style: TextStyle(
                                color: _selectedFile != null 
                                    ? Theme.of(context).primaryColor 
                                    : Colors.grey[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
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
              
              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sudah punya akun? ',
                    style: TextStyle(color: Colors.grey[700]),
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
    super.dispose();
  }
}