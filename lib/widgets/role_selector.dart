import 'package:flutter/material.dart';
import 'package:cupang_store_kelompok9/constants/colors.dart';

enum UserRole { user, seller }

class RoleSelector extends StatelessWidget {
  final UserRole selectedRole;
  final ValueChanged<UserRole> onRoleChanged;

  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    bool isUser = selectedRole == UserRole.user;

    return Row(
      children: [
        // Tab Pengguna
        Expanded(
          child: GestureDetector(
            onTap: () => onRoleChanged(UserRole.user),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: isUser ? AppColors.userInactive : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUser ? AppColors.userActive : AppColors.borderForm,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.person,
                      size: 40,
                      color: isUser ? AppColors.userActive : Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    'Pengguna',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isUser ? AppColors.userActive : Colors.grey,
                    ),
                  ),
                  Text(
                    'Cari dan beli cupang',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: isUser ? AppColors.userActive : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Tab Penjual
        Expanded(
          child: GestureDetector(
            onTap: () => onRoleChanged(UserRole.seller),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: !isUser ? AppColors.sellerInactive : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !isUser ? AppColors.sellerActive : AppColors.borderForm,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.storefront_outlined,
                      size: 40,
                      color: !isUser ? AppColors.sellerActive : Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    'Penjual',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: !isUser ? AppColors.sellerActive : Colors.grey,
                    ),
                  ),
                  Text(
                    'Jual cupang Anda',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: !isUser ? AppColors.sellerActive : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}