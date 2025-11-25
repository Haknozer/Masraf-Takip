import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';

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
              'Ana sayfadan yeni grup oluşturabilir veya bir gruba katılabilirsiniz',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
