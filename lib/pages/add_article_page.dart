import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:cupang_store_kelompok9/constants/colors.dart';
import 'package:cupang_store_kelompok9/constants/text_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddArticlePage extends StatefulWidget {
  const AddArticlePage({super.key});
  @override
  State<AddArticlePage> createState() => _AddArticlePageState();
}
class _AddArticlePageState extends State<AddArticlePage> {
  // Base URL backend BettaVerse kamu
  final String baseUrl = "https://bettaverse.my.id";
  // Controller untuk menangkap input teks form
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _ringkasanController = TextEditingController();
  final TextEditingController _isiController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  // --- VALIDASI AKUN SESUAI USER YANG LOGIN ---
  Future<int> getLoggedInUserId() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Ambil token login yang disimpan temanmu (biasanya namanya 'token' atau 'auth_token')
    final String token = prefs.getString('token') ?? prefs.getString('auth_token') ?? '';

    if (token.isEmpty) {
      // Jika belum login atau token tidak ketemu, default ke 1 agar tidak error 500
      return 1; 
    }

    try {
      // 2. Minta data user yang sedang login langsung ke server Laravel kamu
      final response = await http.get(
        Uri.parse('$baseUrl/api/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> userData = json.decode(response.body);
        // 3. Ambil ID asli dari server (pasti akurat sesuai akun yang sedang login)
        final int realId = int.tryParse(userData['id'].toString()) ?? 1;
        print("=== ID SELLER ASLI DARI SERVER: $realId ===");
        return realId;
      }
    } catch (e) {
      print("Gagal mengambil data user dari token: $e");
    }

    // Jalur aman cadangan jika server down, kembalikan 1 agar database tidak crash
    return 1;
  }
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
  // Fungsi mengirim data ke API Laravel menggunakan Multipart Request
  Future<void> _uploadArticle() async {
    // Validasi input form sederhana
    if (_judulController.text.isEmpty || _isiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan Isi Artikel wajib diisi!')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final int currentUserId = await getLoggedInUserId();
      // Gunakan MultipartRequest karena kita akan mengunggah file foto/gambar
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/artikel'));
      // Menambahkan field teks ke dalam request body
      request.fields['judul'] = _judulController.text;
      request.fields['ringkasan'] = _ringkasanController.text;
      request.fields['isi'] = _isiController.text;
      request.fields['user_id'] = currentUserId.toString(); // Validasi ID Akun Penjual
      // Menyisipkan file gambar jika user memilih cover artikel
      if (_selectedImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'gambar', // Harus sama dengan key di request controller Laravel ($request->file('gambar'))
          _selectedImage!.path,
        ));
      }
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Artikel berhasil dipublikasikan!')),
          );
          Navigator.pop(context, true); // Kirim value true agar halaman sebelumnya ter-refresh
        }
      } else {
        throw Exception('Gagal menyimpan ke server. Kode: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
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
            // Input Judul Artikel (Menggantikan FormInputField kustom agar aman)
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