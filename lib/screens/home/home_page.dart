import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: const Text('Ana Sayfa'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home, size: 100, color: AppColors.primary),
            const SizedBox(height: 24),
            Text('Ana Sayfa', style: AppTextStyles.h1),
            const SizedBox(height: 16),
            Text('Hoş geldiniz!', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            authState.when(
              data: (user) {
                if (user != null) {
                  return Column(
                    children: [
                      Text('Kullanıcı: ${user.email}', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 8),
                      Text('UID: ${user.uid}', style: AppTextStyles.caption),
                    ],
                  );
                }
                return const Text('Kullanıcı bulunamadı');
              },
              loading: () => const CircularProgressIndicator(),
              error:
                  (error, stack) =>
                      Text('Hata: $error', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }
}
