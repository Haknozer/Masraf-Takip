import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class CreateGroupAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CreateGroupAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      title: const Text('Grup Oluştur'),
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
