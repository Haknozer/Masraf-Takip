import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';
import '../../screens/groups/create_group_page.dart';

class EmptyGroupsState extends StatelessWidget {
  const EmptyGroupsState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.buttonPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 100, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.sectionMargin),
            Text('Henüz grup yok', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.textSpacing),
            Text(
              'İlk grubunuzu oluşturun veya bir gruba katılın',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateGroupPage()));
              },
              icon: const Icon(Icons.add),
              label: const Text('Grup Oluştur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
