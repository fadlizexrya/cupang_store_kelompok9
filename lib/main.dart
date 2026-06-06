import 'package:flutter/material.dart';
import 'package:cupang_store_kelompok9/constants/colors.dart';
import 'package:cupang_store_kelompok9/pages/login_page.dart';

void main() {
  runApp(const CupangStoreApp());
}

class CupangStoreApp extends StatelessWidget {
  const CupangStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cupang Store',
      theme: ThemeData(
        fontFamily: 'Roboto', 
        primaryColor: AppColors.userActive,
        scaffoldBackgroundColor: AppColors.bgGradienStart,
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}