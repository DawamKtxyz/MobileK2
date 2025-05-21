// lib/screens/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/barber_model.dart';
import '../models/pelanggan_model.dart';
import '../services/auth_service_factory.dart';
import '../utils/constants.dart';
import '../services/pelanggan_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserType userType;
  final dynamic userData;

  const EditProfileScreen({
    Key? key,
    required this.userType,
    required this.userData,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for common fields
  final _namaController = TextEditingController();
  final _teleponController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Controllers for pelanggan specific fields
  final _alamatController = TextEditingController();
  final _tanggalLahirController = TextEditingController();
  
  // Controllers for barber specific fields
  final _spesialisasiController = TextEditingController();
  final _hargaController = TextEditingController();
  
  bool _isLoading = false;
  bool _isObscurePassword = true;
  bool _isObscureConfirmPassword = true;
  DateTime? _selectedDate;

  // Image picker variables
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  String? _webImageData; // For storing image data in web

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _namaController.text = widget.userData.nama;
    _teleponController.text = widget.userData.telepon ?? '';
    
    if (widget.userType == UserType.pelanggan) {
      final pelanggan = widget.userData as Pelanggan;
      _alamatController.text = pelanggan.alamat ?? '';
      
      if (pelanggan.tanggalLahir != null) {
        _selectedDate = DateTime.tryParse(pelanggan.tanggalLahir!);
        _tanggalLahirController.text = _selectedDate != null 
            ? Constants.formatDateShort(_selectedDate!)
            : '';
      }
    } else if (widget.userType == UserType.barber) {
      final barber = widget.userData as Barber;
      _spesialisasiController.text = barber.spesialisasi ?? '';
      _hargaController.text = barber.harga.toInt().toString(); // Convert to integer for UI
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
      helpText: 'Pilih Tanggal Lahir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _tanggalLahirController.text = Constants.formatDateShort(picked);
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      if (kIsWeb) {
        // Implementation for web
        final XFile? pickedFile = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );

        if (pickedFile != null) {
          // For web, read as bytes and store as base64
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImageData = base64Encode(bytes);
            _selectedImage = null; // Reset selectedImage for mobile
          });
        }
      } else {
        // Implementation for mobile
        final XFile? pickedFile = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );

        if (pickedFile != null) {
          setState(() {
            _selectedImage = File(pickedFile.path);
            _webImageData = null; // Reset webImageData for web
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<String?> _uploadProfileImage() async {
    try {
      // Fix the URL being used
      String baseUrl = Constants.baseUrl;
      if (baseUrl.endsWith('/api')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 4);
      }
      
      final url = widget.userType == UserType.barber
          ? '$baseUrl/api/barber/upload-profile-photo'
          : '$baseUrl/api/pelanggan/upload-profile-photo';
      
      final prefs = await SharedPreferences.getInstance();
      final token = widget.userType == UserType.barber 
          ? prefs.getString(Constants.keyBarberToken)
          : prefs.getString(Constants.keyPelangganToken);
      
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      if (kIsWeb) {
        // For web: send as JSON with base64
        if (_webImageData == null) return null;
        
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'X-Requested-With': 'XMLHttpRequest',
          },
          body: json.encode({
            'profile_photo': _webImageData,
            'file_name': 'profile_image.jpg',
          }),
        );
        
        final responseBody = json.decode(response.body);
        
        if (response.statusCode == 200 && responseBody['success'] == true) {
          return responseBody['image_path'];
        } else {
          throw Exception(responseBody['message'] ?? 'Failed to upload image');
        }
      } else {
        // For mobile: send as multipart/form-data
        if (_selectedImage == null) return null;
        
        var request = http.MultipartRequest('POST', Uri.parse(url));
        
        // Add headers
        request.headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Requested-With': 'XMLHttpRequest',
        });
        
        // Add file
        request.files.add(await http.MultipartFile.fromPath(
          'profile_photo',
          _selectedImage!.path,
        ));
        
        // Send request
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        
        final responseBody = json.decode(response.body);
        
        if (response.statusCode == 200 && responseBody['success'] == true) {
          return responseBody['image_path'];
        } else {
          throw Exception(responseBody['message'] ?? 'Failed to upload image');
        }
      }
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return null;
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check password confirmation
    if (_passwordController.text.isNotEmpty) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password dan konfirmasi password tidak sama')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> updateData = {
        'nama': _namaController.text,
        'telepon': _teleponController.text,
      };

      // Add password if provided
      if (_passwordController.text.isNotEmpty) {
        updateData['password'] = _passwordController.text;
      }

      // Upload image if selected
      String? profilePhotoPath;
      if (_selectedImage != null || _webImageData != null) {
        profilePhotoPath = await _uploadProfileImage();
        if (profilePhotoPath != null) {
          updateData['profile_photo'] = profilePhotoPath;
        }
      }

      bool success = false;
      Map<String, dynamic> result = {};

      if (widget.userType == UserType.pelanggan) {
        updateData['alamat'] = _alamatController.text;
        if (_selectedDate != null) {
          updateData['tanggal_lahir'] = _selectedDate!.toIso8601String().split('T')[0];
        }

        // Call pelanggan update API
        result = await _updatePelangganProfile(updateData);
        success = result['success'] ?? false;
      } else if (widget.userType == UserType.barber) {
        updateData['spesialisasi'] = _spesialisasiController.text;
        
        // Parse harga as integer from string
        final hargaString = _hargaController.text.trim();
        if (hargaString.isNotEmpty) {
          try {
            updateData['harga'] = int.parse(hargaString);
          } catch (e) {
            throw Exception('Format harga tidak valid');
          }
        }

        // Call barber update API
        result = await _updateBarberProfile(updateData);
        success = result['success'] ?? false;
      }

      if (success) {
        // Update local storage
        await _updateLocalStorage(result);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Profil berhasil diperbarui')),
          );
          
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        throw Exception(result['message'] ?? 'Gagal memperbarui profil');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>> _updatePelangganProfile(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(Constants.keyPelangganToken);
    
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    // Fix URL base path
    String baseUrl = Constants.baseUrl;
    if (baseUrl.endsWith('/api')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 4);
    }

    // Call API directly using http
    final url = '$baseUrl/api/pelanggan/profile/update';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'X-Requested-With': 'XMLHttpRequest',
      },
      body: json.encode(data),
    );

    final responseBody = json.decode(response.body);

    if (response.statusCode == 200 && responseBody['success'] == true) {
      return responseBody;
    } else {
      throw Exception(responseBody['message'] ?? 'Gagal memperbarui profil');
    }
  }

  Future<Map<String, dynamic>> _updateBarberProfile(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(Constants.keyBarberToken);
    
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    // Fix URL base path
    String baseUrl = Constants.baseUrl;
    if (baseUrl.endsWith('/api')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 4);
    }

    // Pastikan harga dalam format yang benar
    if (data.containsKey('harga')) {
      // Log untuk debugging
      print('Sending harga to API: ${data['harga']}');
      
      // Pastikan harga adalah integer yang valid
      if (data['harga'] is String) {
        data['harga'] = int.tryParse(data['harga']) ?? widget.userData.harga.toInt();
      }
    }

    // Call API
    final url = '$baseUrl/api/barber/update-profile';
    print('Using URL: $url'); // Debug - check the actual URL
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'X-Requested-With': 'XMLHttpRequest',
      },
      body: json.encode(data),
    );

    final responseBody = json.decode(response.body);
    print('Profile update response: $responseBody'); // Debug log

    if (response.statusCode == 200 && responseBody['success'] == true) {
      // Pastikan barber data lengkap
      if (responseBody['barber'] != null) {
        // Pastikan harga tersedia di respons
        var barberData = responseBody['barber'];
        if (barberData['harga'] == null) {
          barberData['harga'] = data['harga'] ?? widget.userData.harga;
        }
        responseBody['barber'] = barberData;
      }
      
      return responseBody;
    } else {
      throw Exception(responseBody['message'] ?? 'Gagal memperbarui profil');
    }
  }

  Future<void> _updateLocalStorage(Map<String, dynamic> result) async {
    final prefs = await SharedPreferences.getInstance();
      
    // Debug output untuk melihat data yang diterima
    print('Result data for storage update: $result');
    
    if (widget.userType == UserType.pelanggan && result['pelanggan'] != null) {
      // Update 'pelanggan' key dengan data lengkap
      await prefs.setString('pelanggan', jsonEncode(result['pelanggan']));
    } else if (widget.userType == UserType.barber && result['barber'] != null) {
      // Pastikan semua field yang diperlukan ada di data barber
      var barberData = result['barber'];
      
      // Pastikan field harga tersedia dan diparse dengan benar
      if (barberData['harga'] == null) {
        // Gunakan harga dari form jika tidak ada dari server
        barberData['harga'] = double.tryParse(_hargaController.text) ?? widget.userData.harga;
      }
      
      await prefs.setString('barber', jsonEncode(barberData));
      
      // Debug output
      print('Updated barber data in storage: $barberData');
    }
  }

  // Helper method to determine which profile image to display
  ImageProvider? _getProfileImage() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    } else if (_webImageData != null) {
      return MemoryImage(base64Decode(_webImageData!));
    } else if (widget.userData.profilePhoto != null) {
      // Use the image URL from the server
      String baseUrl = Constants.baseUrl;
      if (baseUrl.endsWith('/api')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 4);
      }
      return NetworkImage('$baseUrl/storage/${widget.userData.profilePhoto}');
    }
    return null;
  }

  bool _shouldShowDefaultIcon() {
    return _selectedImage == null && _webImageData == null && widget.userData.profilePhoto == null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _updateProfile,
              child: Text(
                'Simpan',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile picture section
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          backgroundImage: _getProfileImage(),
                          child: _shouldShowDefaultIcon()
                              ? Icon(
                                  widget.userType == UserType.barber 
                                      ? Icons.content_cut 
                                      : Icons.person,
                                  size: 60,
                                  color: Theme.of(context).primaryColor,
                                ) 
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.userData.nama,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.userType == UserType.barber ? 'Barber' : 'Pelanggan',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Form fields
              _buildSection(
                'Informasi Pribadi',
                [
                  _buildTextField(
                    controller: _namaController,
                    label: 'Nama Lengkap',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Nama tidak boleh kosong';
                      }
                      if (value!.length > Constants.maxNameLength) {
                        return 'Nama terlalu panjang';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _teleponController,
                    label: 'Nomor Telepon',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value?.isNotEmpty ?? false) {
                        if (!Constants.isValidPhone(value!)) {
                          return 'Format nomor telepon tidak valid';
                        }
                      }
                      return null;
                    },
                  ),
                  if (widget.userType == UserType.pelanggan) ...[
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _alamatController,
                      label: 'Alamat',
                      icon: Icons.location_on_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _buildDateField(),
                  ],
                  if (widget.userType == UserType.barber) ...[
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _spesialisasiController,
                      label: 'Spesialisasi',
                      icon: Icons.content_cut,
                      hint: 'Contoh: Fade Cut, Pompadour, dll',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _hargaController,
                      label: 'Harga Layanan',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      hint: 'Masukkan harga dalam rupiah',
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Harga tidak boleh kosong';
                        }
                        final harga = int.tryParse(value!);
                        if (harga == null || harga <= 0) {
                          return 'Masukkan harga yang valid';
                        }
                        if (harga < 5000) {
                          return 'Harga minimal Rp 5.000';
                        }
                        if (harga > 1000000) {
                          return 'Harga maksimal Rp 1.000.000';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 24),
              
              _buildSection(
                'Keamanan',
                [
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password Baru',
                    icon: Icons.lock_outline,
                    obscureText: _isObscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscurePassword = !_isObscurePassword;
                        });
                      },
                    ),
                    hint: 'Kosongkan jika tidak ingin mengubah password',
                    validator: (value) {
                      if (value?.isNotEmpty ?? false) {
                        if (!Constants.isValidPassword(value!)) {
                          return 'Password minimal ${Constants.minPasswordLength} karakter';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    label: 'Konfirmasi Password Baru',
                    icon: Icons.lock_outline,
                    obscureText: _isObscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscureConfirmPassword = !_isObscureConfirmPassword;
                        });
                      },
                    ),
                    enabled: _passwordController.text.isNotEmpty,
                    validator: (value) {
                      if (_passwordController.text.isNotEmpty) {
                        if (value != _passwordController.text) {
                          return 'Konfirmasi password tidak sama';
                        }
                      }
                      return null;
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Additional info for barber pricing
              if (widget.userType == UserType.barber) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tips Menentukan Harga',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '• Sesuaikan dengan experience dan skill Anda\n'
                              '• Pertimbangkan harga barber lain di area sekitar\n'
                              '• Harga sudah termasuk jasa potong rambut',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // General info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Perubahan yang Anda lakukan akan mempengaruhi informasi profil di seluruh aplikasi.',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        filled: true,
        fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
     maxLines: maxLines,
     enabled: enabled,
     validator: validator,
     onChanged: (value) {
       // Update confirm password field state
       if (label == 'Password Baru') {
         setState(() {});
       }
       
       // Format for barber price field - only keep numeric values
       if (label == 'Harga Layanan' && value.isNotEmpty) {
         // Remove any non-numeric characters
         String numericValue = value.replaceAll(RegExp(r'[^\d]'), '');
         if (numericValue != value) {
           controller.value = TextEditingValue(
             text: numericValue,
             selection: TextSelection.collapsed(offset: numericValue.length),
           );
         }
       }
     },
   );
 }

 Widget _buildDateField() {
   return TextFormField(
     controller: _tanggalLahirController,
     decoration: InputDecoration(
       labelText: 'Tanggal Lahir',
       prefixIcon: const Icon(Icons.calendar_today_outlined),
       border: OutlineInputBorder(
         borderRadius: BorderRadius.circular(12),
       ),
       enabledBorder: OutlineInputBorder(
         borderRadius: BorderRadius.circular(12),
         borderSide: BorderSide(color: Colors.grey[300]!),
       ),
       focusedBorder: OutlineInputBorder(
         borderRadius: BorderRadius.circular(12),
         borderSide: BorderSide(color: Theme.of(context).primaryColor),
       ),
       filled: true,
       fillColor: Colors.grey[50],
     ),
     readOnly: true,
     onTap: _selectDate,
   );
 }

 @override
 void dispose() {
   _namaController.dispose();
   _teleponController.dispose();
   _passwordController.dispose();
   _confirmPasswordController.dispose();
   _alamatController.dispose();
   _tanggalLahirController.dispose();
   _spesialisasiController.dispose();
   _hargaController.dispose();
   super.dispose();
 }
}