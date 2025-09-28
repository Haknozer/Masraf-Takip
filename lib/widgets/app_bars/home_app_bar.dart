import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      title: const Text('Ana Sayfa'),
      elevation: 0,
      actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => _handleLogout(context))],
    );
  }

  void _handleLogout(BuildContext context) async {
    // AuthProvider'ı context'ten al
    final container = ProviderScope.containerOf(context);
    await container.read(authNotifierProvider.notifier).signOut();
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
