import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_text_styles.dart';
import '../../../providers/theme_provider.dart';

class AppearanceCard extends ConsumerWidget {
  const AppearanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Görünüm', style: AppTextStyles.h3),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Karanlık Mod'),
              subtitle: const Text('Uygulamayı koyu tema ile kullan'),
              value: isDark,
              onChanged: (value) {
                ref.read(themeNotifierProvider.notifier).setDarkMode(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
