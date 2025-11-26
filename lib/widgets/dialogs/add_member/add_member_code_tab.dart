import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_text_styles.dart';
import '../../common/copy_button.dart';

class AddMemberCodeTab extends StatelessWidget {
  final String inviteCode;
  final DateTime inviteCodeExpiresAt;

  const AddMemberCodeTab({
    super.key,
    required this.inviteCode,
    required this.inviteCodeExpiresAt,
  });

  String _getDaysUntilExpiry() {
    final now = DateTime.now();
    final difference = inviteCodeExpiresAt.difference(now).inDays;
    return difference.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.code, size: 64, color: AppColors.primary),
        const SizedBox(height: AppSpacing.sectionMargin),
        Text('Davet Kodunu Paylaşın', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        // Kod gösterimi
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Text(inviteCode, style: AppTextStyles.h1.copyWith(color: AppColors.primary, letterSpacing: 4)),
        ),
        const SizedBox(height: 12),
        CopyButton(text: inviteCode, buttonLabel: 'Kodu Kopyala', successMessage: 'Kod kopyalandı!'),
        const SizedBox(height: 8),
        Text(
          'Kod ${_getDaysUntilExpiry()} gün geçerli',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

