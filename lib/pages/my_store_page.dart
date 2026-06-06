import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cupang_store_kelompok9/constants/colors.dart';
import 'package:cupang_store_kelompok9/constants/text_styles.dart';
import 'package:cupang_store_kelompok9/pages/add_product_page.dart';
import 'package:cupang_store_kelompok9/models/produk_model.dart';

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
                            onPressed: () {
                              // Navigasi ke halaman edit atau logika edit mu di sini
                            }
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red), 
                            onPressed: () {
                              // Logika hapus data marketplace mu di sini
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