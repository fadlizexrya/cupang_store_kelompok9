import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cupang_store_kelompok9/constants/colors.dart';
import 'package:cupang_store_kelompok9/constants/text_styles.dart';
import 'package:cupang_store_kelompok9/models/produk_model.dart';

class EditProductPage extends StatefulWidget {
  final Produk product;

  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  String _selectedJenis = 'Halfmoon'; 
  final List<String> _jenisCupang = ['Halfmoon', 'Crown Tail', 'Plakat', 'Double Tail', 'Giant'];

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _stokController = TextEditingController();
  final TextEditingController _noWaController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();

  File? _selectedImage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _namaController.text = widget.product.nama;
    _hargaController.text = widget.product.harga.toString();
    _stokController.text = widget.product.stok.toString();
    _noWaController.text = widget.product.noWa ?? '';
    _deskripsiController.text = widget.product.deskripsi ?? '';
    
    if (_jenisCupang.contains(widget.product.kategori)) {
      _selectedJenis = widget.product.kategori;
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _stokController.dispose();
    _noWaController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil gambar: $e')),
      );
    }
  }

  void _showUpdateConfirmationDialog() {
    if (_namaController.text.isEmpty ||
        _hargaController.text.isEmpty ||
        _stokController.text.isEmpty ||
        _noWaController.text.isEmpty ||
        _deskripsiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon isi semua bidang formulir yang bertanda *')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Perubahan'),
          content: const Text('Apakah anda yakin ingin mengubah?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tidak', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateProduct();
              },
              child: const Text('Ya', style: TextStyle(color: AppColors.sellerActive, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProduct() async {
    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://bettaverse.my.id/api/marketplace/${widget.product.id}'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        'Authorization': 'Bearer $token',
      });

      request.fields['_method'] = 'PUT';
      request.fields['nama'] = _namaController.text;
      request.fields['jenis'] = _selectedJenis; 
      request.fields['harga'] = _hargaController.text;
      request.fields['stok'] = _stokController.text;
      request.fields['no_wa'] = _noWaController.text;
      request.fields['deskripsi'] = _deskripsiController.text;

      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'foto',
            _selectedImage!.path,
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Postingan berhasil diperbarui!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui: Server merespon kode ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan jaringan: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration buildFormDecoration(IconData icon, String hint) {
      return InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderForm)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderForm)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Postingan Cupang', style: AppTextStyles.h1.copyWith(color: Colors.black, fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Foto Cupang *', style: AppTextStyles.label),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _isSubmitting ? null : _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.sellerInactive,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.sellerActive, style: BorderStyle.solid, width: 1),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.file(
                          _selectedImage!,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      )
                    : widget.product.fotoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.network(
                              widget.product.fotoUrl!,
                              width: double.infinity,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_outlined, size: 40, color: AppColors.sellerActive),
                                  SizedBox(height: 8),
                                  Text('Ubah Foto Cupang', style: TextStyle(color: AppColors.sellerActive, fontSize: 14)),
                                ],
                              ),
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, size: 40, color: AppColors.sellerActive),
                              SizedBox(height: 8),
                              Text('Ubah Foto Cupang', style: TextStyle(color: AppColors.sellerActive, fontSize: 14)),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Nama Cupang *', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _namaController,
              enabled: !_isSubmitting,
              decoration: buildFormDecoration(Icons.pets, 'Contoh: Blue Serenity Super'),
            ),
            const SizedBox(height: 20),

            const Text('Jenis Cupang *', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderForm),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedJenis,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  items: _jenisCupang.map((String jenis) {
                    return DropdownMenuItem<String>(
                      value: jenis,
                      child: Text(jenis, style: AppTextStyles.inputText),
                    );
                  }).toList(),
                  onChanged: _isSubmitting ? null : (String? newValue) {
                    setState(() {
                      if (newValue != null) _selectedJenis = newValue;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Harga (Rp) *', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _hargaController,
                        keyboardType: TextInputType.number,
                        enabled: !_isSubmitting,
                        decoration: buildFormDecoration(Icons.payments_outlined, '150000'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Stok *', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _stokController,
                        keyboardType: TextInputType.number,
                        enabled: !_isSubmitting,
                        decoration: InputDecoration(
                          hintText: '1',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderForm)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderForm)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text('Nomor WhatsApp *', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noWaController,
              keyboardType: TextInputType.phone,
              enabled: !_isSubmitting,
              decoration: buildFormDecoration(Icons.phone_android, '0812xxxxxx'),
            ),
            const SizedBox(height: 20),

            const Text('Deskripsi *', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _deskripsiController,
              maxLines: 4,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                hintText: 'Jelaskan kondisi cupang...',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderForm)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderForm)),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _showUpdateConfirmationDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sellerActive,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Simpan Perubahan',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}