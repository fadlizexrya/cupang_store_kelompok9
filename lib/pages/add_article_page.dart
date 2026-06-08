import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cupang_store_kelompok9/constants/colors.dart';
import 'package:cupang_store_kelompok9/constants/text_styles.dart';
import 'package:cupang_store_kelompok9/services/api_service.dart'; 

class AddArticlePage extends StatefulWidget {
  const AddArticlePage({super.key});
  @override
  State<AddArticlePage> createState() => _AddArticlePageState();
}

class _AddArticlePageState extends State<AddArticlePage> {
  // Controller untuk menangkap input teks form
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _ringkasanController = TextEditingController();
  final TextEditingController _isiController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;

  // Fungsi untuk memilih gambar dari galeri HP
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  // 🔥 FUNGSI UPLOAD YANG SUDAH DI-FIX TOTAL MENGGUNAKAN API_SERVICE JALUR KHUSUS ANTI-419
  Future<void> _uploadArticle() async {
    // Validasi input form bray
    if (_judulController.text.isEmpty || 
        _ringkasanController.text.isEmpty || 
        _isiController.text.isEmpty || 
        _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua form dan gambar wajib diisi!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 🚀 Panggil fungsi sakti dari ApiService yang sudah mengunci jalur aman bebas CSRF
      bool success = await ApiService.storeArtikel(
        judul: _judulController.text,
        ringkasan: _ringkasanController.text,
        isi: _isiController.text,
        imagePath: _selectedImage?.path,
      );

      if (!mounted) return; // Pelindung async gap bray

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artikel BettaVerse berhasil dipublikasikan!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Kembali dan beri sinyal true agar list langsung ter-refresh otomatis!
      } else {
        throw Exception('Server menolak menyimpan. Periksa log terminal VPS atau Docker!');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _ringkasanController.dispose();
    _isiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tulis Artikel Baru',
          style: AppTextStyles.h1.copyWith(color: Colors.black, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload Foto Artikel
            const Text('Cover Artikel (Gambar) *', style: AppTextStyles.label),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.sellerInactive,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.sellerActive),
                  image: _selectedImage != null
                      ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                      : null,
                ),
                child: _selectedImage == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.sellerActive),
                          SizedBox(height: 8),
                          Text('Upload Cover Artikel', style: TextStyle(color: AppColors.sellerActive, fontSize: 14)),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            
            // Input Judul Artikel
            const Text('Judul Artikel *', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _judulController,
              decoration: InputDecoration(
                hintText: 'Contoh: Cara Merawat Cupang Halfmoon',
                prefixIcon: const Icon(Icons.title, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderForm)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderForm)),
              ),
            ),
            const SizedBox(height: 20),
            
            // Input Ringkasan Singkat
            const Text('Ringkasan Singkat *', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _ringkasanController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Tulis intisari artikel dalam 1-2 kalimat...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderForm)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderForm)),
              ),
            ),
            const SizedBox(height: 20),
            
            // Input Isi Artikel Lengkap
            const Text('Isi Artikel Lengkap *', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _isiController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Tuliskan isi edukasi atau artikel Anda di sini secara detail...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderForm)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderForm)),
              ),
            ),
            const SizedBox(height: 40),
            
            // Tombol Publish
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _uploadArticle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sellerActive,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Publikasikan Artikel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}