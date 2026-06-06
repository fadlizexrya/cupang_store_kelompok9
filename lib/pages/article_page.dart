import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cupang_store_kelompok9/constants/colors.dart';
import 'package:cupang_store_kelompok9/constants/text_styles.dart';
import 'package:cupang_store_kelompok9/pages/article_detail_page.dart';
import 'package:cupang_store_kelompok9/pages/home_page.dart';
import 'package:cupang_store_kelompok9/pages/market_page.dart';
import 'package:cupang_store_kelompok9/pages/profile_page.dart';

class ArticlePage extends StatefulWidget {
  const ArticlePage({super.key});

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  final int _currentIndex = 2; // Index 2 untuk tab Artikel aktif

  // State manajemen data API
  List<dynamic> _articles = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _waktuAksesSekarang = ''; // Menyimpan jam real-time saat data diakses

  @override
  void initState() {
    super.initState();
    _fetchArticlesFromBackend();
  }

  // Fungsi Mengambil Data Artikel Asli dari Backend Laravel
  Future<void> _fetchArticlesFromBackend() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('https://bettaverse.my.id/api/artikel'),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);
        
        // Mengambil jam & menit sekarang di HP (Format -> HH:mm)
        final DateTime sekarang = DateTime.now();
        final String jam = sekarang.hour.toString().padLeft(2, '0');
        final String menit = sekarang .minute.toString().padLeft(2, '0');
        
        setState(() {
          _waktuAksesSekarang = '$jam:$menit WIB';

          // Menyesuaikan response data dari 'data' wrapper Laravel
          if (decodedData is Map && decodedData['data'] != null) {
            _articles = decodedData['data'];
          } else if (decodedData is List) {
            _articles = decodedData;
          } else {
            _articles = [];
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat data (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal terhubung ke server BettaVerse';
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
        automaticallyImplyLeading: false, // Hilangkan tombol back karena ini menu utama
        title: Text(
          'Artikel Edukasi',
          style: AppTextStyles.h1.copyWith(color: Colors.black, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchArticlesFromBackend,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.userActive),
                        child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                )
              : _articles.isEmpty
                  ? const Center(child: Text('Belum ada artikel edukasi terbaru.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(24.0),
                      itemCount: _articles.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 24),
                      itemBuilder: (context, index) {
                        final article = _articles[index];

                        // ==================== FIX KUNCI UTAMA: PEMBERSIH FOLDER ARTIKELS ====================
                        String cleanImageUrl = '';
                        String rawGambarUrl = article['gambar_url'] ?? '';

                        if (rawGambarUrl.isNotEmpty) {
                          cleanImageUrl = rawGambarUrl.replaceAll('\\', '');
                        } else if (article['gambar'] != null && article['gambar'].toString().isNotEmpty) {
                          String rawPath = article['gambar'].toString().replaceAll('\\', '').replaceAll(RegExp(r'^/+'), '');
                          cleanImageUrl = 'https://bettaverse.my.id/storage/$rawPath';
                        }

                        if (cleanImageUrl.isEmpty) {
                          cleanImageUrl = 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=800&q=80';
                        }
                        // ====================================================================================

                        // 1. FORMAT TANGGAL DARI BACKEND (created_at)
                        String displayTanggal = 'Baru saja';
                        if (article['created_at'] != null) {
                          String rawDate = article['created_at'].toString();
                          if (rawDate.length >= 10) {
                            displayTanggal = rawDate.substring(0, 10); // Hasilnya: YYYY-MM-DD
                          }
                        }

                        return _buildArticleCard(
                          context,
                          article,
                          article['judul'] ?? 'Tanpa Judul',
                          article['ringkasan'] ?? article['isi'] ?? 'Tidak ada ringkasan teks.',
                          displayTanggal,       // Sekarang menggantikan teks 'Terbaru'
                          _waktuAksesSekarang,  // Sekarang menampilkan Jam Selesai Diakses pengguna
                          cleanImageUrl,
                          _fetchArticlesFromBackend, // Passing fungsi refresh ke helper widget
                        );
                      },
                    ),

      // BOTTOM NAVIGATION BAR
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 1, 14, 29).withValues(alpha: 0.3),
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
            } else if (index == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MarketPage()),
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
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Marketplace'),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Artikel'), // Aktif
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}

// Helper Widget untuk Kartu Artikel Premium (Desain asli dipertahankan penuh)
Widget _buildArticleCard(
  BuildContext context, 
  Map<String, dynamic> articleData, 
  String title, 
  String summary, 
  String uploadDate, // Mengambil parameter tanggal database
  String accessTime, // Mengambil parameter jam akses real-time
  String imageUrl,
  VoidCallback onRefresh // Callback untuk mentrigger pengambilan data ulang
) {
  return GestureDetector(
    onTap: () async {
      // Tunggu sampai user kembali dari detail page
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArticleDetailPage(
            article: articleData,
            heroImageUrl: imageUrl,
          ),
        ),
      );
      // Ketika kembali, jalankan fungsi refresh data
      onRefresh();
    },
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderForm),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 1, 14, 29).withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.network(
              imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 180,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bagian Meta Data (Icon tetap sama, data teks diubah)
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(accessTime, style: const TextStyle(fontSize: 12, color: Colors.grey)), // Menampilkan Waktu Selesai Baca/Akses
                    const SizedBox(width: 16),
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(uploadDate, style: const TextStyle(fontSize: 12, color: Colors.grey)), // Menampilkan Tanggal Asli Upload Laravel
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title, 
                  style: AppTextStyles.h1.copyWith(fontSize: 18), 
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis
                ),
                const SizedBox(height: 8),
                Text(
                  summary, 
                  style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.4), 
                  maxLines: 3, 
                  overflow: TextOverflow.ellipsis
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Baca selengkapnya', style: AppTextStyles.link.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 16, color: AppColors.textLink),
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