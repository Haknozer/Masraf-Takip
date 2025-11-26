import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_text_styles.dart';
import '../../common/copy_button.dart';
import '../../common/copyable_text_field.dart';

class AddMemberLinkTab extends StatelessWidget {
  final String inviteCode;

  const AddMemberLinkTab({super.key, required this.inviteCode});

  @override
  Widget build(BuildContext context) {
    final webLink = 'https://masraftakipuygulamasi.web.app/join?code=$inviteCode';

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.link, size: 64, color: AppColors.primary),
        const SizedBox(height: AppSpacing.sectionMargin),
        Text('Linki paylaşın', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Bu link hem web tarayıcısında hem uygulamada çalışır',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        // Web Link gösterimi
        CopyableTextField(text: webLink),
        const SizedBox(height: 8),
        CopyButton(text: webLink, buttonLabel: 'Linki Kopyala', successMessage: 'Link kopyalandı!'),
      ],
    );
  }
}

