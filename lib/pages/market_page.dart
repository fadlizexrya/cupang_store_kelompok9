import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'product_detail_page.dart'; 
import 'package:cupang_store_kelompok9/constants/colors.dart';
import 'package:cupang_store_kelompok9/constants/text_styles.dart';
import 'package:cupang_store_kelompok9/pages/home_page.dart';
import 'package:cupang_store_kelompok9/pages/article_page.dart';
import 'package:cupang_store_kelompok9/pages/profile_page.dart';
import 'package:cupang_store_kelompok9/models/produk_model.dart'; 

class MarketPage extends StatefulWidget {
  final bool initialSearch; 
  final int initialCategoryIndex;
  const MarketPage({
    super.key, 
    this.initialSearch = false, 
    this.initialCategoryIndex = 0, 
  });

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  final int _currentIndex = 1; 
  late int _selectedFilterIndex; 
  
  List<Produk> _allProducts = []; 
  List<Produk> _displayedProducts = []; 
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedFilterIndex = widget.initialCategoryIndex; 
    _fetchMarketplaceData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMarketplaceData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://bettaverse.my.id/api/marketplace'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          final List<dynamic> dataLog = responseData['data'] ?? [];
          setState(() {
            _allProducts = dataLog.map((json) => Produk.fromJson(json)).toList();
            _isLoading = false;
          });
          _filterAndSearchProducts();
        }
      } else {
        _showErrorSnackBar('Gagal memuat data (${response.statusCode})');
        _disableLoading();
      }
    } catch (e) {
      _showErrorSnackBar('Gagal terhubung ke server BettaVerse');
      _disableLoading();
    }
  }

  void _disableLoading() {
    setState(() {
      _isLoading = false;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _filterAndSearchProducts() {
    String currentCategory = _filters[_selectedFilterIndex];
    
    setState(() {
      _displayedProducts = _allProducts.where((product) {
        String productName = product.nama.toLowerCase();
        String productBadge = product.kategori.toLowerCase();

        bool matchesCategory = currentCategory == 'Semua' || 
            productBadge.trim() == currentCategory.toLowerCase().trim();
            
        bool matchesSearch = productName.contains(_searchQuery.toLowerCase());

        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  final List<String> _filters = [
    'Semua',
    'Halfmoon',
    'Crown Tail',
    'Plakat',
    'Giant',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Marketplace Cupang',
          style: AppTextStyles.h1.copyWith(color: Colors.black, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderForm),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: widget.initialSearch,
                          onChanged: (value) {
                            _searchQuery = value;
                            _filterAndSearchProducts();
                          },
                          decoration: const InputDecoration(
                            hintText: 'Cari cupang impianmu...',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      bool isSelected = _selectedFilterIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilterIndex = index;
                          });
                          _filterAndSearchProducts();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.userActive : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: isSelected
                                    ? AppColors.userActive
                                    : AppColors.borderForm),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _filters[index],
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _displayedProducts.isEmpty
                    ? const Center(child: Text('Tidak ada ikan cupang yang cocok.'))
                    : RefreshIndicator(
                        onRefresh: _fetchMarketplaceData,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(24),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, 
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.61, 
                          ),
                          itemCount: _displayedProducts.length,
                          itemBuilder: (context, index) {
                            final product = _displayedProducts[index];
                            return _buildGridCupangCard(product);
                          },
                        ),
                      ),
          ),
        ],
      ),
      
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (_currentIndex == index) return;

            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            } else if (index == 2) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ArticlePage()),
              );
            } else if (index == 3) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.userActive,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Marketplace'), 
            BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Artikel'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCupangCard(Produk product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              title: product.nama,
              price: "Rp ${product.harga}",
              seller: product.namaToko,
              badge: product.kategori,
              imageUrl: product.fotoUrl ?? 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=300&q=80',
              description: product.deskripsi, 
              noWa: product.noWa,             
              stok: product.stok, // REVISI: Kirim jumlah stok ke halaman detail
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.borderForm, width: 1.5), 
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(13.5)), 
                  child: Image.network(
                    product.fotoUrl ?? 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=300&q=80',
                    height: 125, 
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 125, 
                      width: double.infinity,
                      color: Colors.grey[200], 
                      child: const Icon(Icons.image, color: Colors.grey, size: 40),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.userActive, 
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      product.kategori,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF28A745).withOpacity(0.8), 
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Tersedia',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nama,
                    style: AppTextStyles.label.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Rp ${product.harga}",
                    style: AppTextStyles.label.copyWith(
                        color: AppColors.userActive, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Stok: ${product.stok} ekor",
                    style: TextStyle(
                      color: product.stok > 5 ? Colors.grey[600] : Colors.orange[700], 
                      fontSize: 11,
                      fontWeight: FontWeight.w500
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 8,
                        backgroundColor: AppColors.borderForm,
                        child: Icon(Icons.storefront, size: 10, color: Colors.grey),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.namaToko,
                          style: TextStyle(color: Colors.grey[600], fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}