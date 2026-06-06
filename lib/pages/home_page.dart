import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cupang_store_kelompok9/constants/colors.dart';
import 'package:cupang_store_kelompok9/constants/text_styles.dart';
import 'package:cupang_store_kelompok9/pages/market_page.dart';
import 'package:cupang_store_kelompok9/pages/article_detail_page.dart';
import 'package:cupang_store_kelompok9/pages/profile_page.dart';
import 'package:cupang_store_kelompok9/pages/article_page.dart';
import 'package:cupang_store_kelompok9/models/produk_model.dart';
import 'package:cupang_store_kelompok9/pages/product_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String _displayName = "..."; 

  List<dynamic> _latestArticles = [];
  bool _isArticlesLoading = true;

  List<Produk> _cupangPilihanProducts = [];
  bool _isLoadingProducts = true;

  // Variabel baru untuk mengontrol teks pencarian langsung di Home
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchLatestArticles();
    _fetchCupangPilihanData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _displayName = prefs.getString('user_name') ?? "User";
    });
  }

  Future<void> _fetchCupangPilihanData() async {
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
            _cupangPilihanProducts = dataLog.map((json) => Produk.fromJson(json)).toList();
            _isLoadingProducts = false;
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
      setState(() { _isLoadingProducts = false; });
    }
  }

  Future<void> _fetchLatestArticles() async {
    try {
      final response = await http.get(
        Uri.parse('https://bettaverse.my.id/api/artikel'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);
        List<dynamic> rawList = [];

        if (decodedData is Map && decodedData['data'] != null) {
          rawList = decodedData['data'];
        } else if (decodedData is List) {
          rawList = decodedData;
        }

        setState(() {
          _latestArticles = rawList.take(2).toList();
          _isArticlesLoading = false;
        });
      } else {
        setState(() => _isArticlesLoading = false);
      }
    } catch (e) {
      setState(() => _isArticlesLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Memfilter list berdasarkan teks yang diketik secara realtime/setelah selesai submit
    final filteredProducts = _cupangPilihanProducts.where((product) {
      return product.nama.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER SECTION
            Container(
              padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF005AFF), Color(0xFF6D28D9)],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Halo, $_displayName!',
                                    style: AppTextStyles.h1.copyWith(color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Jelajahi dunia ikan cupang',
                              style: AppTextStyles.subtitle.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/logo.png', 
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 52,
                            height: 52,
                            color: Colors.white24,
                            child: const Icon(Icons.gavel, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // DIUBAH: Dari GestureDetector menjadi Container berisi TextField asli (Tampilan luar mutlak sama)
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) {
                        setState(() {
                          _searchQuery = value; // Filter dijalankan pas tombol search di keyboard diklik
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari cupang impianmu...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _searchQuery.isNotEmpty 
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = "";
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. CUPANG PILIHAN SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildSectionHeader('Cupang Pilihan', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MarketPage()),
                );
              }),
            ),
            const SizedBox(height: 16),
            SizedBox(
                height: 200, 
                child: _isLoadingProducts
                    ? const Center(child: CircularProgressIndicator())
                    : filteredProducts.isEmpty // Menggunakan data hasil filter pencarian
                        ? const Center(child: Text('Tidak ada ikan cupang pilihan.'))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            scrollDirection: Axis.horizontal,
                            itemCount: filteredProducts.length > 5 ? 5 : filteredProducts.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              return _buildHomeCupangCard(product); 
                            },
                          ),
              ),
            const SizedBox(height: 32),

            // 3. ARTIKEL TERBARU SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildSectionHeader('Artikel Terbaru', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ArticlePage()),
                );
              }),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _isArticlesLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _latestArticles.isEmpty
                      ? const Center(child: Text('Belum ada artikel edukasi terbaru.'))
                      : Column(
                          children: List.generate(_latestArticles.length, (index) {
                            final article = _latestArticles[index];

                            String cleanImageUrl = '';
                            String rawGambarUrl = article['gambar_url'] ?? '';
                            if (rawGambarUrl.isNotEmpty) {
                              cleanImageUrl = rawGambarUrl.replaceAll('\\', '');
                            } else if (article['gambar'] != null && article['gambar'].toString().isNotEmpty) {
                              String rawPath = article['gambar'].toString().replaceAll('\\', '').replaceAll(RegExp(r'^/+'), '');
                              cleanImageUrl = 'https://bettaverse.my.id/storage/$rawPath';
                            }

                            if (cleanImageUrl.isEmpty) {
                              cleanImageUrl = 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=150&q=80';
                            }

                            return Padding(
                              padding: EdgeInsets.only(bottom: index == _latestArticles.length - 1 ? 0 : 12),
                              child: _buildArticleCard(
                                article,
                                article['judul'] ?? 'Tanpa Judul',
                                article['ringkasan'] ?? article['isi'] ?? 'Tidak ada ringkasan teks.',
                                cleanImageUrl,
                              ),
                            );
                          }),
                        ),
            ),
            const SizedBox(height: 32),

            // 4. KATEGORI CUPANG SECTION
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text('Kategori Cupang', style: AppTextStyles.h1),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildCategoryItem('🌙', 'Halfmoon', 1),
                  _buildCategoryItem('👑', 'Crown Tail', 2),
                  _buildCategoryItem('⚡', 'Plakat', 3),
                  _buildCategoryItem('✨', 'Double Tail', 0),
                  _buildCategoryItem('🦈', 'Giant', 4),
                  _buildCategoryItem('🐟', 'Semua', 0),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),

      // 5. BOTTOM NAVIGATION BAR
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
            setState(() => _currentIndex = index);
            
            Widget targetPage;
            switch (index) {
              case 1: targetPage = const MarketPage(); break;
              case 2: targetPage = const ArticlePage(); break;
              case 3: targetPage = const ProfilePage(); break;
              default: return;
            }
            
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => targetPage),
            );
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.userActive,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Marketplace'),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Artikel'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.h1),
        GestureDetector(
          onTap: onSeeAll,
          child: Text('Lihat Semua →', style: AppTextStyles.link),
        ),
      ],
    );
  }

  Widget _buildHomeCupangCard(Produk product) {
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
              stok: product.stok, 
            ),
          ),
        );
      },
      child: Container(
        width: 160, 
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
                    height: 110, 
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 110, 
                      width: double.infinity,
                      color: Colors.grey[200], 
                      child: const Icon(Icons.image, color: Colors.grey, size: 30),
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
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
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
                    style: AppTextStyles.label.copyWith(color: AppColors.userActive, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Stok: ${product.stok} ekor",
                    style: TextStyle(
                      color: product.stok > 5 ? Colors.grey[600] : Colors.orange[700], 
                      fontSize: 10,
                      fontWeight: FontWeight.w500
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(dynamic articleData, String title, String description, String imageUrl) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(
          builder: (context) => ArticleDetailPage(article: articleData),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderForm),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(imageUrl, width: 70, height: 70, fit: BoxFit.cover),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.label.copyWith(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String emoji, String title, int filterIndex) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MarketPage(initialCategoryIndex: filterIndex),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderForm),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(title, style: AppTextStyles.label.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}