import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cupang_store_kelompok9/constants/colors.dart';
import 'package:cupang_store_kelompok9/constants/text_styles.dart';

class EditProfilePage extends StatefulWidget {
  final String currentName;
  final String currentEmail;
  final String currentAlamat;
  final String currentShopName;
  final String role;

  const EditProfilePage({
    super.key,
    required this.currentName,
    required this.currentEmail,
    required this.currentAlamat,
    required this.currentShopName,
    required this.role,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _alamatController;
  late TextEditingController _shopNameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Memastikan form terisi dari parameter asli yang login saat ini
    _nameController = TextEditingController(text: widget.currentName);
    _emailController = TextEditingController(text: widget.currentEmail);
    _alamatController = TextEditingController(text: widget.currentAlamat);
    _shopNameController = TextEditingController(text: widget.currentShopName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _alamatController.dispose();
    _shopNameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfileChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse('https://bettaverse.my.id/api/update-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': _nameController.text,
          'email': _emailController.text,
          'address': _alamatController.text, // Disinkronkan menjadi 'address' sesuai Laravel
          if (widget.role.toLowerCase() == 'seller') 'shop_name': _shopNameController.text,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        //final responseData = jsonDecode(response.body);
        
        // Simpan cache lokal baru
        await prefs.setString('user_name', _nameController.text);
        await prefs.setString('user_email', _emailController.text);
        await prefs.setString('user_alamat', _alamatController.text);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil berhasil diperbarui!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // Sukses, kembali dan reload profile_page
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showError(errorData['message'] ?? 'Gagal menyimpan (${response.statusCode})');
      }
    } catch (e) {
      _showError('Tidak ada koneksi ke server');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    bool isPenjual = widget.role.toLowerCase() == 'seller';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profil Saya',
          style: AppTextStyles.h1.copyWith(color: Colors.black, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _isSaving 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.userActive, width: 2),
                            ),
                            child: const CircleAvatar(
                              radius: 45,
                              backgroundColor: Color(0xFFF1F3F5),
                              child: Icon(Icons.person, size: 50, color: AppColors.userActive),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    const Text('Nama Lengkap', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama Anda',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (value) => value!.isEmpty ? 'Nama tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 20),

                    const Text('Alamat Email', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Masukkan email Anda',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (value) => value!.isEmpty ? 'Email tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 20),

                    const Text('Alamat Rumah Lengkap', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _alamatController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Masukkan alamat pengiriman lengkap',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      validator: (value) => value!.isEmpty ? 'Alamat wajib diisi' : null,
                    ),
                    
                    // NAMA TOKO DISERIKAN SECARA DINAMIS: Hanya dirender jika status user == penjual
                    if (isPenjual) ...[
                      const SizedBox(height: 20),
                      const Text('Nama Toko Anda', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _shopNameController,
                        decoration: InputDecoration(
                          hintText: 'Masukkan nama toko cupang Anda',
                          prefixIcon: const Icon(Icons.storefront, color: AppColors.userActive),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (value) => isPenjual && value!.isEmpty ? 'Nama toko wajib diisi oleh penjual' : null,
                      ),
                    ],

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saveProfileChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.userActive,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Simpan Perubahan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}