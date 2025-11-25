import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class CreateGroupHeader extends StatelessWidget {
  const CreateGroupHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Icon(Icons.group_add, size: 80, color: AppColors.primary),
        const SizedBox(height: 24),
        Text('Yeni Grup Oluştur', style: AppTextStyles.h2, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Arkadaşlarınızla masrafları paylaşın',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}
