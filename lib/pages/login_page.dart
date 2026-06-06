import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; 
import 'package:cupang_store_kelompok9/constants/colors.dart';
import 'package:cupang_store_kelompok9/constants/text_styles.dart';
import 'package:cupang_store_kelompok9/widgets/role_selector.dart';
import 'package:cupang_store_kelompok9/pages/register_page.dart';
import 'package:cupang_store_kelompok9/pages/home_page.dart'; 
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  UserRole _selectedRole = UserRole.user;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _prosesLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorSnackBar('Email dan Password tidak boleh kosong!');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.post(
        Uri.parse('https://bettaverse.my.id/api/login'),
        headers: {
          'Accept': 'application/json',
        },
        body: {
          'email': _emailController.text,
          'password': _passwordController.text,
          'role': _selectedRole == UserRole.user ? 'user' : 'seller',
        },
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      Navigator.pop(context); // Tutup Loading

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        SharedPreferences prefs = await SharedPreferences.getInstance();
        
        String? token = data['access_token'] ?? data['token']; 
        
        if (token != null) {
          await prefs.setString('token', token);
          
          // --- LOGIKA SIMPAN NAMA USER ---
          if (data['user'] != null && data['user']['name'] != null) {
            await prefs.setString('user_name', data['user']['name']);
          }

          await prefs.setString('role', _selectedRole == UserRole.user ? 'user' : 'seller');
        }

        if (!mounted) return;
        _showSuccessSnackBar('Login berhasil!');

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      } else {
        // Menangkap pesan error/validasi role yang dikirim oleh backend Laravel
        final errorData = jsonDecode(response.body);
        _showErrorSnackBar(errorData['message'] ?? 'Login gagal, periksa akun kamu');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); 
      _showErrorSnackBar('Gagal terhubung ke server! Cek koneksi internet kamu.');
      print("Error Login: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: _selectedRole == UserRole.user ? AppColors.userActive : AppColors.sellerActive
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isUser = _selectedRole == UserRole.user;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.bgGradienStart,
              AppColors.bgGradienMid,
              Color(0xFF6D28D9),
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 40, bottom: 30),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/logo.png', 
                          height: 90, 
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, size: 70, color: Colors.white),
                        ), 
                        const SizedBox(height: 16),
                        Text('BettaVerse', style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 28)),
                        const SizedBox(height: 4),
                        Text('Login untuk melanjutkan', style: AppTextStyles.subtitle.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Selamat Datang Kembali!', style: AppTextStyles.h1),
                            const SizedBox(height: 24),
                            
                            RoleSelector(
                              selectedRole: _selectedRole,
                              onRoleChanged: (role) {
                                setState(() {
                                  _selectedRole = role;
                                });
                              },
                            ),
                            const SizedBox(height: 24),
                            
                            const Text('Email', style: AppTextStyles.label),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'nama@email.com',
                                prefixIcon: const Icon(Icons.mail_outline),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            const Text('Password', style: AppTextStyles.label),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: '●●●●●●●●',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      height: 24, width: 24,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) {
                                          setState(() { _rememberMe = value ?? false; });
                                        },
                                        activeColor: AppColors.textBody,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Ingat saya', style: TextStyle(fontSize: 14, color: AppColors.textBody)),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                  child: const Text('Lupa password?', style: AppTextStyles.link),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _prosesLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isUser ? AppColors.userActive : AppColors.sellerActive,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(
                                  isUser ? 'Login sebagai Pengguna' : 'Login sebagai Penjual',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            Center(
                              child: RichText(
                                text: TextSpan(
                                  text: 'Belum punya akun? ',
                                  style: AppTextStyles.inputText.copyWith(color: AppColors.textBody, fontSize: 14),
                                  children: [
                                    TextSpan(
                                      text: 'Daftar sekarang',
                                      style: AppTextStyles.link.copyWith(fontWeight: FontWeight.bold),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}