import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Pastikan ini diimport
import 'package:cupang_store_kelompok9/constants/colors.dart';
import 'package:cupang_store_kelompok9/constants/text_styles.dart';
import 'package:cupang_store_kelompok9/pages/home_page.dart';
import 'package:cupang_store_kelompok9/pages/market_page.dart';
import 'package:cupang_store_kelompok9/pages/article_page.dart';
import 'package:cupang_store_kelompok9/pages/login_page.dart';
import 'package:cupang_store_kelompok9/pages/my_store_page.dart';
import 'package:cupang_store_kelompok9/pages/edit_profile_page.dart';
import 'package:cupang_store_kelompok9/pages/help_center_page.dart';
import 'package:cupang_store_kelompok9/pages/my_article_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final int _currentIndex = 3;
  bool _isLoading = true;

  // Inisialisasi default yang aman: Kunci ke data kosong dan role 'pengguna'
  String _name = 'Memuat...';
  String _email = '';
  String _role = 'pengguna'; 
  String _alamat = '';
  String _shopName = '';

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? ''; 

      final response = await http.get(
        Uri.parse('https://bettaverse.my.id/api/user-profile'), 
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token', 
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Laravel langsung return object user nya ($request->user())
        final Map<String, dynamic> userData = jsonDecode(response.body);

        setState(() {
          _name = userData['name'] ?? 'Pengguna Cupang';
          _email = userData['email'] ?? '';
          _role = userData['role'] ?? 'user'; // 'user' atau 'seller' dari DB
          _alamat = userData['address'] ?? ''; // Memetakan key 'address' dari DB
          _shopName = userData['shop_name'] ?? '';
          _isLoading = false;
        });
      } else {
        _showErrorSnackBar('Gagal memuat profil (${response.statusCode})');
        _setSecureFallbackData();
      }
    } catch (e) {
      _setSecureFallbackData();
    }
  }

  // PROTEKSI: Jika API Error / 401, data dipaksa ke mode 'pengguna/user' agar fitur toko tidak bocor terbuka!
  void _setSecureFallbackData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Mengambil cadangan data user lokal saat login jika API offline
      _name = prefs.getString('user_name') ?? 'Pengguna BettaVerse';
      _email = prefs.getString('user_email') ?? 'zakaria123@gmail.com';
      _role = prefs.getString('user_role') ?? 'pengguna'; 
      _alamat = prefs.getString('user_alamat') ?? 'Belum mengatur alamat';
      _shopName = prefs.getString('user_shop_name') ?? '';
      _isLoading = false;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Validasi ketat penentuan role penjual
    bool isPenjual = _role.toLowerCase() == 'seller';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppColors.userActive,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Profil Saya',
          style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // 1. Header Profil
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(bottom: 30, top: 20),
                    decoration: const BoxDecoration(
                      color: AppColors.userActive,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, size: 50, color: AppColors.userActive),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isPenjual && _shopName.isNotEmpty ? _shopName : _name,
                          style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 22),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _email,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isPenjual ? 'Akun Penjual' : 'Akun Pengguna',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 2. Bagian Menu Utama
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HANYA MUNCUL JIKA BENAR-BENAR SEBAGAI PENJUAL
                        if (isPenjual) ...[
                          const Text('Aktivitas Saya', style: AppTextStyles.label),
                          const SizedBox(height: 12),
                          
                          _buildMenuCard(
                            Icons.storefront_outlined, 
                            'Postingan Toko Saya', 
                            'Kelola ikan cupang yang Anda jual',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyStorePage())),
                          ),
                          const SizedBox(height: 12),

                          _buildMenuCard(
                            Icons.article_outlined, 
                            'Artikel Edukasi Saya', 
                            'Kelola artikel dan tulisan Anda',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyArticlePage())),
                          ),
                          const SizedBox(height: 12),
                        ],
                        
                        const Text('Pengaturan', style: AppTextStyles.label),
                        const SizedBox(height: 12),
                        _buildMenuCard(
                          Icons.person_outline, 
                          'Edit Profil', 
                          isPenjual ? 'Ubah data diri, alamat dan nama toko' : 'Ubah data diri dan alamat',
                          onTap: () async {
                            final result = await Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (context) => EditProfilePage(
                                  currentName: _name,
                                  currentEmail: _email,
                                  currentAlamat: _alamat,
                                  currentShopName: _shopName,
                                  role: _role,
                                )
                              )
                            );
                            if (result == true) {
                              _fetchUserProfile(); // Reload otomatis saat kembali ke halaman ini
                            }
                          }
                        ),
                        const SizedBox(height: 12),
                        _buildMenuCard(
                          Icons.help_outline, 
                          'Pusat Bantuan', 
                          'Hubungi admin aplikasi',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpCenterPage())),
                        ),

                        const SizedBox(height: 32),
                        
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.clear(); // Hapus session login token
                              if (mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginPage()),
                                  (route) => false,
                                );
                              }
                            },
                            icon: const Icon(Icons.logout, color: Colors.red),
                            label: const Text(
                              'Keluar Akun',
                              style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (_currentIndex == index) return; 
            if (index == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
            if (index == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MarketPage()));
            if (index == 2) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ArticlePage()));
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.userActive,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Marketplace'),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Artikel'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'), 
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(IconData icon, String title, String subtitle, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderForm),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.userInactive,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.userActive),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.label.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}