import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:cupang_store_kelompok9/constants/colors.dart';
import 'package:cupang_store_kelompok9/constants/text_styles.dart';
import 'package:cupang_store_kelompok9/widgets/role_selector.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  UserRole _selectedRole = UserRole.user;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _shopNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- LOGIKA REGISTER KE SERVER ---
  Future<void> _handleRegister() async {
    // 1. Validasi Input
    if (_fullNameController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _passwordController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _addressController.text.isEmpty) {
      _showSnackBar('Semua kolom bertanda * wajib diisi!', Colors.red);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Konfirmasi password tidak cocok!', Colors.red);
      return;
    }

    // Validasi tambahan jika memilih penjual, nama toko wajib diisi
    if (_selectedRole == UserRole.seller && _shopNameController.text.isEmpty) {
      _showSnackBar('Nama Toko wajib diisi untuk Penjual!', Colors.red);
      return;
    }

    // 2. Loading Overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 3. Request ke Laravel
      final response = await http.post(
        Uri.parse('https://bettaverse.my.id/api/register'),
        headers: {
          'Accept': 'application/json', // Menolak return HTML error dari Laravel
        },
        body: {
          'name': _fullNameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
          'role': _selectedRole == UserRole.user ? 'user' : 'seller', // Mengirimkan role dinamis
          'shop_name': _selectedRole == UserRole.user ? '' : _shopNameController.text,
        },
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      Navigator.pop(context); // Tutup Loading

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Registrasi Berhasil! Silakan Login.', Colors.green);
        Navigator.pop(context); // Balik ke halaman Login
      } else {
        final errorData = jsonDecode(response.body);
        _showSnackBar(errorData['message'] ?? 'Registrasi Gagal!', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar('Terjadi kesalahan koneksi atau timeout!', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
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
              AppColors.bgGradienEnd,
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        Image.asset(
                          'assets/images/logo.png', 
                          height: 60,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, size: 60, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Text('Daftar Akun Baru', style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 24)),
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
                            const Text('Bergabung bersama kami!', style: AppTextStyles.h1),
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

                            _buildInputField('Nama Lengkap *', Icons.person_outline, 'Nama lengkap Anda', _fullNameController),
                            
                            if (!isUser) ...[
                              const SizedBox(height: 16),
                              _buildInputField('Nama Toko *', Icons.storefront_outlined, 'Contoh: Toko Cupang Jaya', _shopNameController),
                            ],

                            const SizedBox(height: 16),
                            _buildInputField('Email *', Icons.mail_outline, 'email@example.com', _emailController, keyboardType: TextInputType.emailAddress),
                            
                            const SizedBox(height: 16),
                            _buildInputField('Nomor Telepon *', Icons.phone_android_outlined, '081234567890', _phoneController, keyboardType: TextInputType.phone),
                            
                            const SizedBox(height: 16),
                            _buildInputField('Alamat *', Icons.location_on_outlined, 'Alamat lengkap Anda', _addressController, keyboardType: TextInputType.streetAddress),

                            const SizedBox(height: 16),
                            const Text('Password *', style: AppTextStyles.label),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: '●●●●●●●●',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () { setState(() { _obscurePassword = !_obscurePassword; }); },
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),

                            const SizedBox(height: 16),
                            const Text('Konfirmasi Password *', style: AppTextStyles.label),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                hintText: '●●●●●●●●',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () { setState(() { _obscureConfirmPassword = !_obscureConfirmPassword; }); },
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isUser ? AppColors.userActive : AppColors.sellerActive,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(
                                  isUser ? 'Daftar sebagai Pengguna' : 'Daftar sebagai Penjual',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            Center(
                              child: RichText(
                                text: TextSpan(
                                  text: 'Sudah punya akun? ',
                                  style: AppTextStyles.inputText.copyWith(color: AppColors.textBody, fontSize: 14),
                                  children: [
                                    TextSpan(
                                      text: 'Login di sini',
                                      style: AppTextStyles.link.copyWith(fontWeight: FontWeight.bold),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          Navigator.pop(context);
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

  Widget _buildInputField(String label, IconData icon, String hint, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}