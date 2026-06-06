import 'package:flutter/material.dart';
import 'package:cupang_store_kelompok9/constants/colors.dart';

class AppTextStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textBody,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textBody,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.textBody,
  );

  static const TextStyle inputText = TextStyle(
    fontSize: 16,
    color: AppColors.textBody,
  );

  static const TextStyle placeholder = TextStyle(
    fontSize: 16,
    color: Colors.grey,
  );

  static const TextStyle link = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textLink,
  );
}