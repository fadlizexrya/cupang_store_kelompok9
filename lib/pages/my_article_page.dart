import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cupang_store_kelompok9/constants/colors.dart';
import 'package:cupang_store_kelompok9/constants/text_styles.dart';
import 'package:cupang_store_kelompok9/pages/add_article_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cupang_store_kelompok9/pages/edit_article_page.dart';

class MyArticlePage extends StatefulWidget {
  const MyArticlePage({super.key});

  @override
  State<MyArticlePage> createState() => _MyArticlePageState();
}

class _MyArticlePageState extends State<MyArticlePage> {
  // Base URL backend BettaVerse kamu
  final String baseUrl = "https://bettaverse.my.id";
  
  // Future variabel untuk mencegah trigger berulang-ulang di FutureBuilder saat setState
  late Future<List<dynamic>> _myArticlesFuture;

  @override
  void initState() {
    super.initState();
    _refreshArticles();
  }

  // Fungsi helper untuk memicu refresh data bray
  void _refreshArticles() {
    setState(() {
      _myArticlesFuture = fetchMyArticles();
    });
  }

  // Mengambil ID penjual asli yang saat ini sedang login dari local session HP
  Future<int> getLoggedInUserId() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Ambil token login yang disimpan oleh sistem login kelompokmu
    final String token = prefs.getString('token') ?? prefs.getString('auth_token') ?? '';

    if (token.isEmpty) {
      return 1; 
    }

    try {
      // PERBAIKAN ENDPOINT: Menyesuaikan route default auth Sanctum Laravel (/api/user-profile)
      final response = await http.get(
        Uri.parse('$baseUrl/api/user-profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // Antisipasi jika response dibungkus key 'data' oleh AuthApiController bray
        final Map<String, dynamic> userData = responseData['data'] ?? responseData;
        
        final int realId = int.tryParse(userData['id'].toString()) ?? 1;
        return realId;
      }
    } catch (e) {
      print("Gagal mengambil session user di MyArticlePage: $e");
    }

    return 1;
  }

  // Fungsi mengambil data artikel asli dari backend Laravel dan memfilternya
  Future<List<dynamic>> fetchMyArticles() async {
    try {
      // 1. Ambil ID user yang login secara dinamis sesuai session (Fuad / Asep)
      final int currentUserId = await getLoggedInUserId();

      // 2. Request semua data artikel ke API Backend BettaVerse
      final response = await http.get(Uri.parse('$baseUrl/api/artikel'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // Sesuai dengan getArtikel() di ContentApiController, data dibungkus di key 'data'
        final List<dynamic> allArticles = responseData['data'] ?? [];

        // 3. VALIDASI FILTER: Saring artikel, hanya ambil yang user_id-nya COCOK dengan akun yang sedang login bray!
        final List<dynamic> filteredArticles = allArticles.where((artikel) {
          final int artikelUserId = int.tryParse(artikel['user_id'].toString()) ?? 0;
          return artikelUserId == currentUserId;
        }).toList();

        return filteredArticles;
      } else {
        throw Exception('Gagal memuat data dari server');
      }
    } catch (e) {
      throw Exception('Kesalahan koneksi: $e');
    }
  }

  // FUNGSI UTAMA MENGHAPUS ARTIKEL KE BACKEND LARAVEL
  Future<void> deleteArtikel(int artikelId) async {
    final prefs = await SharedPreferences.getInstance();
    final String token = prefs.getString('token') ?? prefs.getString('auth_token') ?? '';

    try {
      // Kirim request DELETE ke endpoint backend bray
      final response = await http.delete(
        Uri.parse('$baseUrl/api/artikel/$artikelId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Artikel berhasil dihapus!'),
            backgroundColor: Colors.green, // MODIFIKASI: Hijau jika berhasil bray
          ),
        );
        // Langsung refresh data setelah sukses bray!
        _refreshArticles();
      } else {
        final Map<String, dynamic> res = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal menghapus artikel'),
            backgroundColor: Colors.red, // MODIFIKASI: Merah jika gagal dari server
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan koneksi: $e'),
          backgroundColor: Colors.red, // MODIFIKASI: Merah jika gagal koneksi bray
        ),
      );
    }
  }

  // DIALOG KONFIRMASI SEBELUM HAPUS
  void konfirmasiHapus(int artikelId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah anda ingin menghapus artikel ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Tutup dialog jika klik Tidak
              child: const Text('Tidak', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog dulu bray
                deleteArtikel(artikelId); // Jalankan fungsi hapus
              },
              child: const Text('Ya', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
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
          'Artikel Edukasi Saya',
          style: AppTextStyles.h1.copyWith(color: Colors.black, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _myArticlesFuture, // Menggunakan instance future ter-cache agar stabil saat di-refresh
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // Tampilan jika akun ini belum pernah membuat artikel sama sekali
            return const Center(child: Text('Belum ada artikel yang ditulis.'));
          }

          final listArtikel = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: listArtikel.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final artikel = listArtikel[index];

              // FIX BUG IMAGE URL: Di backend ContentApiController, path-nya sudah otomatis dikonversi
              // menjadi URL penuh absolut lewat asset('storage/' . $item->gambar), jadi langsung dipanggil bray!
              final String imageUrl = artikel['gambar_url'] ?? '';
              final String finalImageUrl = imageUrl.isNotEmpty
                  ? imageUrl
                  : 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=100&q=80'; 

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderForm),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        finalImageUrl,
                        height: 70,
                        width: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            height: 70,
                            width: 70,
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            artikel['judul'] ?? 'Tanpa Judul',
                            style: AppTextStyles.label.copyWith(fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Bagian info Suka & Tidak Suka di bawah judul sudah dihapus total bray
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.userActive),
                      onPressed: () {
                        // Navigasi ke halaman Edit membawa map data artikel terpilih
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditArticlePage(artikel: artikel),
                          ),
                        ).then((value) {
                          if (value == true) {
                            // Jika kembali membawa sinyal sukses (true), segarkan halaman otomatis
                            _refreshArticles();
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        // Ambil ID artikel asli dari database bray
                        final int idHapus = int.tryParse(artikel['id'].toString()) ?? 0;
                        if (idHapus != 0) {
                          konfirmasiHapus(idHapus);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ID artikel tidak valid'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddArticlePage()),
          ).then((value) {
            // Memanggil fungsi refresh data total setelah kembali dari AddArticlePage bray
            _refreshArticles();
          });
        },
        backgroundColor: AppColors.sellerActive,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tulis Artikel',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}