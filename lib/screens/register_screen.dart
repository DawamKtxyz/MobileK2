import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';

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
  final _authService = AuthService();
  
  bool _isLoading = false;
  PlatformFile? _selectedFile;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
        print('Selected file path: ${_selectedFile?.path}');
        print('Selected file name: ${_selectedFile?.name}');
      });
    }
  }

  Future<void> _register() async {
    // Validasi form
    if (!_formKey.currentState!.validate()) return;

    // Validasi file
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan upload sertifikat PDF')),
      );
      return;
    }

    // Periksa ukuran file (maksimal 2MB)
    if (_selectedFile!.size > 2 * 1024 * 1024) { // 2MB
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ukuran file maksimal 2MB')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Cari path file yang valid
      String? filePath;
      if (_selectedFile!.path != null) {
        filePath = _selectedFile!.path!;
      } else if (_selectedFile!.bytes != null) {
        // Jika path null, simpan bytes ke file sementara
        final tempFile = File('${Directory.systemTemp.path}/${_selectedFile!.name}');
        await tempFile.writeAsBytes(_selectedFile!.bytes!);
        filePath = tempFile.path;
      }

      if (filePath == null) {
        throw Exception('Tidak dapat menemukan path file');
      }

      // Siapkan data untuk registrasi
      final registrationData = {
        'nama': _namaController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'telepon': _teleponController.text,
        'spesialisasi': _spesialisasiController.text.isEmpty 
          ? null 
          : _spesialisasiController.text,
        'sertifikat': filePath, // Path file
      };

      // Panggil metode register
      final success = await _authService.register(registrationData);

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
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _namaController,
                label: 'Nama Lengkap',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
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
              CustomTextField(
                controller: _spesialisasiController,
                label: 'Spesialisasi (Opsional)',
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickFile,
                child: Text(_selectedFile != null 
                  ? 'Sertifikat: ${_selectedFile!.name}' 
                  : 'Upload Sertifikat'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Daftar'),
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
    super.dispose();
  }
}