import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cupang_store_kelompok9/constants/colors.dart';
import 'package:cupang_store_kelompok9/constants/text_styles.dart';

class ArticleDetailPage extends StatefulWidget {
  final Map<String, dynamic> article;
  final String? heroImageUrl;

  const ArticleDetailPage({
    super.key, 
    required this.article,
    this.heroImageUrl,
  });

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  // State interaksi dinamis untuk fitur Like & Dislike
  bool _isLiked = false;
  bool _isDisliked = false;
  int _likeCount = 46; 
  int _dislikeCount = 5; 

  String _waktuSelesaiBaca = '';

  @override
  void initState() {
    super.initState();
    _inisialisasiWaktuSelesaiAkses();
    _inisialisasiDataInteraksi();
  }

  // Fungsi mencatat waktu real-time kapan pengguna membaca halaman detail ini hingga selesai
  void _inisialisasiWaktuSelesaiAkses() {
    final DateTime sekarang = DateTime.now();
    final String jam = sekarang.hour.toString().padLeft(2, '0');
    final String menit = sekarang.minute.toString().padLeft(2, '0');
    setState(() {
      _waktuSelesaiBaca = '$jam:$menit WIB';
    });
  }

  // Sinkronisasi data counter dari database backend Laravel secara nyata
  void _inisialisasiDataInteraksi() {
    setState(() {
      _likeCount = int.tryParse(widget.article['likes_count'].toString()) ?? 46;
      _dislikeCount = int.tryParse(widget.article['dislikes_count'].toString()) ?? 5;
      
      // Status kondisi klik user awal dari API Laravel (jika terikat session/user auth)
      _isLiked = widget.article['is_liked'] ?? false;
      _isDisliked = widget.article['is_disliked'] ?? false;
    });
  }

  // ==================== FUNGSIONALITAS API KIRIM KE BACKEND ====================
  Future<void> _updateInteraksiKeBackend(String type) async {
    final int articleId = widget.article['id'] ?? 0;
    if (articleId == 0) return;

    try {
      final response = await http.post(
        Uri.parse('https://bettaverse.my.id/api/artikel/$articleId/$type'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('Berhasil sinkronisasi: ${response.body}');
      } else {
        debugPrint('Gagal sinkronisasi: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Terjadi gangguan jaringan: $e');
    }
  }
  // ==============================================================================

  // Aksi tombol Like & Unlike fungsional + Sinkronisasi API
  void _handleLikeAction() {
    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _likeCount--;
      } else {
        _isLiked = true;
        _likeCount++;
        if (_isDisliked) {
          _isDisliked = false;
          _dislikeCount--;
        }
      }
    });
    // Kirim trigger perubahan secara asinkron ke server
    _updateInteraksiKeBackend('like');
  }

  // Aksi tombol Dislike & Undislike fungsional + Sinkronisasi API
  void _handleDislikeAction() {
    setState(() {
      if (_isDisliked) {
        _isDisliked = false;
        _dislikeCount--;
      } else {
        _isDisliked = true;
        _dislikeCount++;
        if (_isLiked) {
          _isLiked = false;
          _likeCount--;
        }
      }
    });
    // Kirim trigger perubahan secara asinkron ke server
    _updateInteraksiKeBackend('dislike');
  }

  @override
  Widget build(BuildContext context) {
    // ==================== REVISI DIREKTORI & PEMBERSIH URL GAMBAR ====================
    String cleanImageUrl = widget.heroImageUrl ?? '';

    if (cleanImageUrl.isEmpty) {
      String rawGambarUrl = widget.article['gambar_url'] ?? '';

      if (rawGambarUrl.isNotEmpty) {
        cleanImageUrl = rawGambarUrl.replaceAll('\\', '');
      } else if (widget.article['gambar'] != null && widget.article['gambar'].toString().isNotEmpty) {
        String rawPath = widget.article['gambar'].toString().replaceAll('\\', '').replaceAll(RegExp(r'^/+'), '');
        cleanImageUrl = 'https://bettaverse.my.id/storage/$rawPath';
      }

      if (cleanImageUrl.isEmpty) {
        cleanImageUrl = 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=800&q=80';
      }
    }
    // =================================================================================

    // DATA DINAMIS NAMA PEMBUAT
    String namaPembuat = 'Fadli'; 
    if (widget.article['user'] != null && widget.article['user']['name'] != null) {
      namaPembuat = widget.article['user']['name'].toString();
    } else if (widget.article['penulis'] != null) {
      namaPembuat = widget.article['penulis'].toString();
    } else if (widget.article['creator'] != null) {
      namaPembuat = widget.article['creator'].toString();
    }

    // DATA DINAMIS TANGGAL UPLOAD
    String displayTanggal = 'Baru saja';
    if (widget.article['created_at'] != null) {
      String rawDate = widget.article['created_at'].toString();
      if (rawDate.length >= 10) {
        displayTanggal = rawDate.substring(0, 10); 
      }
    }

    String judul = widget.article['judul'] ?? 'Tanpa Judul';
    String ringkasan = widget.article['ringkasan'] ?? 'Panduan mendalam mengenai ikan cupang edukatif.';
    String isiKonten = widget.article['isi'] ?? 'Tidak ada konten artikel.';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Detail Artikel',
          style: AppTextStyles.h1.copyWith(color: Colors.black, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Gambar Header Dinamis
            Image.network(
              cleanImageUrl,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 220,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.image_not_supported, color: Colors.grey, size: 50),
                  ),
                );
              },
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Judul Artikel Dinamis
                  Text(
                    judul,
                    style: AppTextStyles.h1.copyWith(fontSize: 22, height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  
                  // 3. Meta Data Dinamis Menampilkan Nama Pembuat, Tanggal Asli, dan Jam Real-time Selesai Akses
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.userInactive,
                        child: Icon(Icons.person, size: 16, color: AppColors.userActive),
                      ),
                      const SizedBox(width: 8),
                      Text(namaPembuat, style: AppTextStyles.label.copyWith(fontSize: 14)), 
                      const SizedBox(width: 16),
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(displayTanggal, style: const TextStyle(color: Colors.grey, fontSize: 12)), 
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(_waktuSelesaiBaca, style: const TextStyle(color: Colors.grey, fontSize: 12)), 
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // 4. Subjudul / Deskripsi Singkat Dinamis
                  Text(
                    ringkasan,
                    style: AppTextStyles.subtitle.copyWith(fontStyle: FontStyle.italic, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: AppColors.borderForm),
                  const SizedBox(height: 24),
                  
                  // 5. Konten Artikel Dinamis
                  Text('Artikel Lengkap', style: AppTextStyles.h1.copyWith(fontSize: 18)),
                  const SizedBox(height: 16),
                  
                  Text(
                    isiKonten,
                    style: AppTextStyles.inputText.copyWith(height: 1.6, fontSize: 15),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 32),
                  
                  // 6. Box Tips
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.userInactive,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.userActive.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              text: 'Tips: ',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.userActive, fontSize: 14),
                              children: [
                                TextSpan(
                                  text: 'Bagikan artikel ini kepada teman-teman Anda yang juga tertarik dengan dunia ikan cupang!',
                                  style: TextStyle(fontWeight: FontWeight.normal, color: Colors.grey[800], height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(color: AppColors.borderForm),
                  const SizedBox(height: 16),
                  
                  // 7. Feedback Section Fungsional Like & Dislike
                  Row(
                    children: [
                      Expanded( 
                        child: Text('Apakah artikel ini membantu?', style: AppTextStyles.label.copyWith(fontSize: 14)),
                      ),
                      const SizedBox(width: 8),
                      // Tombol Like / Unlike Fungsional
                      GestureDetector(
                        onTap: _handleLikeAction,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isLiked ? AppColors.userInactive : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            border: _isLiked ? Border.all(color: AppColors.userActive) : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined, 
                                size: 16, 
                                color: _isLiked ? AppColors.userActive : Colors.grey[700]
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$_likeCount', 
                                style: TextStyle(
                                  color: _isLiked ? AppColors.userActive : Colors.grey[800], 
                                  fontWeight: FontWeight.bold
                                )
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Tombol Dislike / Undislike Fungsional
                      GestureDetector(
                        onTap: _handleDislikeAction,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isDisliked ? Colors.red[50] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            border: _isDisliked ? Border.all(color: Colors.red) : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isDisliked ? Icons.thumb_down_alt : Icons.thumb_down_alt_outlined, 
                                size: 16, 
                                color: _isDisliked ? Colors.red : Colors.grey[700]
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$_dislikeCount', 
                                style: TextStyle(
                                  color: _isDisliked ? Colors.red : Colors.grey[800], 
                                  fontWeight: FontWeight.bold
                                )
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}