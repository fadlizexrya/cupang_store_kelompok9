import 'package:flutter/material.dart';
import 'package:cupang_store_kelompok9/constants/text_styles.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text('Pusat Bantuan', style: AppTextStyles.h1.copyWith(color: Colors.black, fontSize: 20)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Pertanyaan Populer (FAQ)', style: AppTextStyles.h1),
          const SizedBox(height: 16),
          _buildFAQ('Bagaimana cara menghubungi penjual?', 'Anda dapat menekan tombol "Hubungi via WhatsApp" pada halaman detail cupang.'),
          _buildFAQ('Apakah aplikasi menyediakan fitur pembayaran?', 'Tidak, aplikasi ini hanya sebagai marketplace dan sistem informasi. Transaksi dilakukan di luar aplikasi.'),
          _buildFAQ('Bagaimana cara menjadi penjual?', 'Anda bisa memilih role "Penjual" saat melakukan registrasi akun baru.'),
        ],
      ),
    );
  }

  Widget _buildFAQ(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(question, style: AppTextStyles.label),
        children: [Padding(padding: const EdgeInsets.all(16.0), child: Text(answer, style: TextStyle(color: Colors.grey[700])))],
      ),
    );
  }
}