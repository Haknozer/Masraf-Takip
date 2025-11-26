import 'package:flutter/material.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_text_styles.dart';
import '../../forms/custom_button.dart';

class AccountSettingsCard extends StatelessWidget {
  final TextEditingController nameController;
  final VoidCallback onChangePassword;

  const AccountSettingsCard({super.key, required this.nameController, required this.onChangePassword});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Hesap Ayarları', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.textSpacing),
            Text('Kullanıcı Adı', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      nameController.text,
                      style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionMargin),
            CustomButton(text: 'Şifreyi Değiştir', icon: Icons.lock_reset, onPressed: onChangePassword),
          ],
        ),
      ),
    );
  }
}
