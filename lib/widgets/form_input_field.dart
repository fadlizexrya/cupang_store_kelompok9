import 'package:flutter/material.dart';
import 'package:cupang_store_kelompok9/constants/colors.dart';
import 'package:cupang_store_kelompok9/constants/text_styles.dart';

class FormInputField extends StatelessWidget {
  final IconData prefixIcon;
  final String label;
  final String hintText;
  final bool obscureText;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final TextInputType keyboardType;

  const FormInputField({
    super.key,
    required this.prefixIcon,
    required this.label,
    required this.hintText,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 8),
        TextFormField(
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: AppTextStyles.inputText,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.placeholder,
            prefixIcon: Icon(prefixIcon, color: Colors.grey),
            suffixIcon: suffixIcon != null
                ? IconButton(
                    icon: Icon(suffixIcon, color: Colors.grey),
                    onPressed: onSuffixIconPressed,
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderForm),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderForm),
            ),
          ),
        ),
      ],
    );
  }
}