import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cupang_store_kelompok9/constants/colors.dart';
import 'package:cupang_store_kelompok9/constants/text_styles.dart';
import 'package:cupang_store_kelompok9/services/api_service.dart'; 

class EditArticlePage extends StatefulWidget {
  final Map<String, dynamic> artikel; // Menerima data artikel yang akan diedit

  const EditArticlePage({super.key, required this.artikel});

  @override
  State<EditArticlePage> createState() => _EditArticlePageState();
}

class _EditArticlePageState extends State<EditArticlePage> {
  // Controller diisi otomatis menggunakan data yang di-passing dari halaman list
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _ringkasanController = TextEditingController();
  final TextEditingController _isiController = TextEditingController();
  
  File? _selectedImage;
  String? _existingImageUrl; // Untuk menampung URL gambar lama dari backend
  bool _isLoading = false;
  int? _artikelId;

  @override
  void initState() {
    super.initState();
    // Memasukkan data awal artikel ke dalam form input
    _artikelId = int.tryParse(widget.artikel['id'].toString());
    _judulController.text = widget.artikel['judul'] ?? '';
    _ringkasanController.text = widget.artikel['ringkasan'] ?? '';
    _isiController.text = widget.artikel['isi'] ?? '';
    _existingImageUrl = widget.artikel['gambar_url'];
  }

  // Fungsi untuk memilih gambar baru dari galeri HP
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  // Dialog validasi sebelum mengirim data ke server
  void _konfirmasiSimpan() {
    if (_judulController.text.isEmpty || 
        _ringkasanController.text.isEmpty || 
        _isiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua form wajib diisi!'), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Perubahan'),
          content: const Text('Apakah anda yakin ingin mengubah?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Tutup dialog jika Tidak
              child: const Text('Tidak', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog konfirmasi
                _updateArticle(); // Jalankan fungsi update data
              },
              child: const Text('Ya', style: TextStyle(color: AppColors.userActive, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Fungsi kirim data perubahan ke Backend Laravel via ApiService
  Future<void> _updateArticle() async {
    if (_artikelId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Panggil fungsi penanganan update di ApiService kelompokmu
      // Pastikan method di ApiService menangani method spoofing PUT/PATCH jika multiparts form data
      bool success = await ApiService.updateArtikel(
        id: _artikelId!,
        judul: _judulController.text,
        ringkasan: _ringkasanController.text,
        isi: _isiController.text,
        imagePath: _selectedImage?.path, // Bernilai null jika user tidak mengganti gambar
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artikel berhasil diperbarui!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Kembali ke halaman utama dengan sinyal true agar reload otomatis
      } else {
        throw Exception('Server gagal menyimpan perubahan artikel.');
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
          'Edit Artikel',
          style: AppTextStyles.h1.copyWith(color: Colors.black, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload / Preview Foto Artikel
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
                      : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                          ? DecorationImage(image: NetworkImage(_existingImageUrl!), fit: BoxFit.cover)
                          : null,
                ),
                child: _selectedImage == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty)
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
            
            // Tombol Perbarui Perubahan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _konfirmasiSimpan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sellerActive,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Simpan Perubahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}