// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/barber_auth_service.dart';
import '../services/pelanggan_auth_service.dart';
import '../services/auth_service_factory.dart';
import '../widgets/custom_text_field.dart';
import 'register_screen.dart';
import 'pelanggan_register_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _barberAuthService = BarberAuthService();
  final _pelangganAuthService = PelangganAuthService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  UserType _selectedUserType = UserType.barber; // Default selection

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        bool success;
        
        // Login based on selected user type
        if (_selectedUserType == UserType.barber) {
          success = await _barberAuthService.login(
            _emailController.text,
            _passwordController.text,
          );
        } else {
          success = await _pelangganAuthService.login(
            _emailController.text,
            _passwordController.text,
          );
        }
        
        if (success) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login gagal. Periksa email dan password Anda.')),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // Logo and app name
                  Column(
                    children: [
                      Icon(
                        Icons.content_cut,
                        size: 64,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'BarberGo',
                        style: TextStyle(
                          fontSize: 32, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Potong rambut jadi lebih mudah',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // User type selection
                  Container(
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
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedUserType = UserType.barber;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _selectedUserType == UserType.barber
                                    ? Theme.of(context).primaryColor
                                    : Colors.white,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Barber',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _selectedUserType == UserType.barber
                                        ? Colors.white
                                        : Colors.grey,
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
                                _selectedUserType = UserType.pelanggan;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _selectedUserType == UserType.pelanggan
                                    ? Theme.of(context).primaryColor
                                    : Colors.white,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Pelanggan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _selectedUserType == UserType.pelanggan
                                        ? Colors.white
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Masukkan email anda',
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
                  
                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Masukkan password anda',
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
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Login button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
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
                          : Text(
                              'Login sebagai ${_selectedUserType == UserType.barber ? 'Barber' : 'Pelanggan'}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Belum punya akun? ',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Navigate to the appropriate register screen
                          if (_selectedUserType == UserType.barber) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PelangganRegisterScreen(),
                              ),
                            );
                          }
                        },
                        child: Text(
                          'Daftar',
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
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}