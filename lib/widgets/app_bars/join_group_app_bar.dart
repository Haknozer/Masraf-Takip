import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class JoinGroupAppBar extends StatelessWidget implements PreferredSizeWidget {
  const JoinGroupAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      title: const Text('Gruba Katıl'),
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
