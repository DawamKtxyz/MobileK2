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
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'BarberGo',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 48),
                
                // User type selection
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Login Sebagai:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<UserType>(
                                title: const Text('Barber'),
                                value: UserType.barber,
                                groupValue: _selectedUserType,
                                onChanged: (UserType? value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedUserType = value;
                                    });
                                  }
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<UserType>(
                                title: const Text('Pelanggan'),
                                value: UserType.pelanggan,
                                groupValue: _selectedUserType,
                                onChanged: (UserType? value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedUserType = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
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
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : Text('Login sebagai ${_selectedUserType == UserType.barber ? 'Barber' : 'Pelanggan'}'),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                TextButton(
                  onPressed: () {
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
                    'Belum punya akun ${_selectedUserType == UserType.barber ? 'Barber' : 'Pelanggan'}? Daftar',
                  ),
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}