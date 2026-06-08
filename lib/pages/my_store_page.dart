import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cupang_store_kelompok9/constants/colors.dart';
import 'package:cupang_store_kelompok9/constants/text_styles.dart';
import 'package:cupang_store_kelompok9/pages/add_product_page.dart';
import 'package:cupang_store_kelompok9/models/produk_model.dart';
import 'package:cupang_store_kelompok9/pages/edit_product_page.dart';

class MyStorePage extends StatefulWidget {
  const MyStorePage({super.key});

  @override
  State<MyStorePage> createState() => _MyStorePageState();
}

class _MyStorePageState extends State<MyStorePage> {
  List<Produk> _myProducts = [];
  bool _isLoading = true;
  String _currentSellerName = "";

  @override
  void initState() {
    super.initState();
    _loadSellerAndFetchProducts();
  }

  // Mengambil nama akun yang sedang login, kemudian mengambil data produk dari API
  Future<void> _loadSellerAndFetchProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Mengambil nama user yang login (misal: "fuad" atau "fadli")
      _currentSellerName = prefs.getString('user_name') ?? "";

      final response = await http.get(
        Uri.parse('https://bettaverse.my.id/api/marketplace'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          final List<dynamic> dataLog = responseData['data'] ?? [];
          
          // Mengubah JSON menjadi objek model Produk
          final List<Produk> allProducts = dataLog.map((json) => Produk.fromJson(json)).toList();

          setState(() {
            // FILTER UTAMA: Hanya masukkan produk yang nama toko/penjualnya cocok dengan user yang sedang login
            _myProducts = allProducts.where((product) => 
              product.namaToko.toLowerCase().trim() == _currentSellerName.toLowerCase().trim()
            ).toList();
            
            _isLoading = false;
          });
        }
      } else {
        _disableLoading();
      }
    } catch (e) {
      _disableLoading();
    }
  }

  // FUNGSI UTAMA UNTUK MENGHAPUS POSTINGAN VIA API
  Future<void> _deleteProduct(int id) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String token = prefs.getString('token') ?? '';

      // Menembak endpoint delete REST API Laravel BettaVerse kelompokmu bray
      final response = await http.delete(
        Uri.parse('https://bettaverse.my.id/api/marketplace/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Jika sukses di server, hapus item dari list lokal dan segarkan UI bray
        setState(() {
          _myProducts.removeWhere((product) => product.id == id);
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Postingan berhasil dihapus!'), backgroundColor: Colors.green),
          );
        }
      } else {
        _disableLoading();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus dari server: ${response.statusCode}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      _disableLoading();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan koneksi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // FUNGSI KONFIRMASI VALIDASI DENGAN DIALOG ALERT
  void _showDeleteConfirmationDialog(int productId) {
    showDialog(
      context: context,
      barrierDismissible: false, // User wajib berinteraksi dengan menekan tombol bray
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah anda yakin ingin menghapus?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Klik Tidak -> Menutup dialog bray
              child: const Text('Tidak', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog konfirmasi terlebih dahulu
                _deleteProduct(productId); // Jalankan fungsi eksekusi hapus bray
              },
              child: const Text('Ya', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _disableLoading() {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
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
          onPressed: () => Navigator.pop(context)
        ),
        title: Text(
          'Postingan Toko Saya', 
          style: AppTextStyles.h1.copyWith(color: Colors.black, fontSize: 20)
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myProducts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Kamu belum pernah membuat postingan marketplace.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: _myProducts.length, 
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final product = _myProducts[index];

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(16), 
                        border: Border.all(color: AppColors.borderForm)
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12), 
                            child: Image.network(
                              product.fotoUrl ?? 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=100&q=80', 
                              height: 70, 
                              width: 70, 
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 70,
                                width: 70,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.nama, 
                                  style: AppTextStyles.label.copyWith(fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rp ${product.harga}', 
                                  style: TextStyle(color: AppColors.sellerActive, fontWeight: FontWeight.bold)
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Stok: ${product.stok}', 
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12)
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.userActive), 
                            onPressed: () async {
                              // Berpindah ke halaman edit dengan membawa data produk terpilih
                              final isUpdated = await Navigator.push(
                                context, 
                                MaterialPageRoute(
                                  builder: (context) => EditProductPage(product: product),
                                ),
                              );
                              
                              // Jika data berhasil disimpan, segarkan otomatis list produk di toko
                              if (isUpdated == true) {
                                _loadSellerAndFetchProducts();
                              }
                            }
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red), 
                            onPressed: () {
                              // MENGAKSIKAN FILTER DIALOG KONFIRMASI DENGAN MELEMPARKAN ID PRODUK BRAY
                              _showDeleteConfirmationDialog(product.id);
                            }
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProductPage()));
        },
        backgroundColor: AppColors.sellerActive,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Cupang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}