import 'package:flutter/material.dart';
import 'package:cupang_store_kelompok9/constants/colors.dart';
import 'package:cupang_store_kelompok9/constants/text_styles.dart';
import 'package:url_launcher/url_launcher.dart'; 

class ProductDetailPage extends StatelessWidget {
  final String title;
  final String price;
  final String seller;
  final String badge;
  final String imageUrl;
  final String description; 
  final String noWa;       
  final int stok; // REVISI: Menampung data stok dari database MySQL

  const ProductDetailPage({
    super.key,
    required this.title,
    required this.price,
    required this.seller,
    required this.badge,
    required this.imageUrl,
    required this.description, 
    required this.noWa,        
    required this.stok, // Ditambahkan ke constructor wajib
  });

  Future<void> _launchWhatsApp(BuildContext context) async {
    String formattedNoWa = noWa.trim();
    
    if (formattedNoWa.startsWith('0')) {
      formattedNoWa = '62${formattedNoWa.substring(1)}';
    }

    final String message = Uri.encodeComponent(
      'Halo $seller, saya tertarik dengan ikan cupang *"$title"* seharga *$price* di BettaVerse. Apakah masih tersedia?'
    );
    
    final Uri whatsappUri = Uri.parse('https://wa.me/$formattedNoWa?text=$message');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $whatsappUri';
      }
    } catch (e) {
      if (!context.mounted) return; // Mengamankan async gap bray biar ga kuning warning linter-nya
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka WhatsApp ke nomor: $noWa'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            backgroundColor: AppColors.userActive,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey, size: 50),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(0.0, -1.0),
                        end: Alignment(0.0, -0.5),
                        colors: <Color>[Color(0x60000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge Kategori
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.userInactive,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(badge, style: AppTextStyles.label.copyWith(color: AppColors.userActive, fontSize: 12)),
                  ),
                  const SizedBox(height: 16),
                  
                  // Judul dan Harga
                  Text(title, style: AppTextStyles.h1.copyWith(fontSize: 24)),
                  const SizedBox(height: 8),
                  Text(price, style: AppTextStyles.h1.copyWith(color: AppColors.userActive, fontSize: 22)),
                  
                  // REVISI: Menampilkan info Stok Tepat di Bawah Harga tanpa merusak layout
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 16, color: stok > 3 ? Colors.grey[600] : Colors.orange[800]),
                      const SizedBox(width: 6),
                      Text(
                        'Stok Tersedia: $stok',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: stok > 3 ? Colors.grey[700] : Colors.orange[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  const Divider(color: AppColors.borderForm),
                  const SizedBox(height: 24),
                  
                  // POSISI BARU: Deskripsi Cupang Naik ke Atas
                  const Text('Deskripsi Produk', style: AppTextStyles.h1),
                  const SizedBox(height: 12),
                  Text(
                    description.isNotEmpty 
                        ? description 
                        : 'Ikan cupang jenis $badge dengan kualitas premium. Tidak ada deskripsi tambahan untuk produk ini.',
                    style: AppTextStyles.inputText.copyWith(height: 1.5),
                  ),
                  
                  const SizedBox(height: 24),
                  const Divider(color: AppColors.borderForm),
                  const SizedBox(height: 16),
                  
                  // POSISI BARU: Info Nama Toko/Penjual Turun ke Bawah Deskripsi
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.sellerInactive,
                        child: Icon(Icons.storefront, color: AppColors.sellerActive, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nama akun diubah ukurannya jadi lebih besar (fontSize: 20) dan tebal biar mirip Nama Toko utama bray
                            Text(
                              seller, 
                              style: AppTextStyles.h1.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100), 
                ],
              ),
            ),
          ),
        ],
      ),
      
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchWhatsApp(context),
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text('Hubungi via WhatsApp', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 19, 182, 79), 
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}