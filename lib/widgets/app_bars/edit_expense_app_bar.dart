import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class EditExpenseAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EditExpenseAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      title: const Text('Masraf Düzenle'),
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

