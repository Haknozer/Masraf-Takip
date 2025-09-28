import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class RegisterHeader extends StatelessWidget {
  const RegisterHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Icon(Icons.account_balance_wallet, size: 80, color: AppColors.primary),
        const SizedBox(height: 24),
        Text('Hesap Oluştur', style: AppTextStyles.h2, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Masraf takip uygulamasına katılmak için hesap oluşturun',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}
