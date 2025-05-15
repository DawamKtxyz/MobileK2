import 'package:flutter/material.dart';
import '../models/barber_model.dart';
import '../services/api_service.dart';
import '../widgets/custom_text_field.dart';
import '../utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  final Barber barber;

  const EditProfileScreen({Key? key, required this.barber}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _teleponController;
  late TextEditingController _spesialisasiController;
  final _apiService = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.barber.nama);
    _teleponController = TextEditingController(text: widget.barber.telepon);
    _spesialisasiController = TextEditingController(text: widget.barber.spesialisasi);
  }

Future<void> _updateProfile() async {
  if (_formKey.currentState!.validate()) {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token tidak ditemukan. Silakan login kembali.')),
        );
        return;
      }

      final response = await _apiService.post(
        Constants.updateProfileEndpoint,
        {
          'nama': _namaController.text,
          'telepon': _teleponController.text,
          'spesialisasi': _spesialisasiController.text,
        },
        token: token, // Menambahkan token ke header
      );

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui profil')),
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
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
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
                label: 'Spesialisasi',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Simpan Perubahan'),
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
    _teleponController.dispose();
    _spesialisasiController.dispose();
    super.dispose();
  }
}