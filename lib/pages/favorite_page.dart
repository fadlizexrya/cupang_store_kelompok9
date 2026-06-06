import 'package:flutter/material.dart';
import 'package:cupang_store_kelompok9/constants/text_styles.dart';

class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text('Cupang Favorit', style: AppTextStyles.h1.copyWith(color: Colors.black, fontSize: 20)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Belum ada cupang favorit', style: AppTextStyles.h1.copyWith(color: Colors.grey, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}