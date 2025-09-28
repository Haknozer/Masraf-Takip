import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class GroupDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GroupDetailAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      title: const Text('Grup Detayı'),
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            // Group settings
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
