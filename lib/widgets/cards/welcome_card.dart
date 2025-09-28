import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class WelcomeCard extends StatelessWidget {
  final AsyncValue authState;

  const WelcomeCard({super.key, required this.authState});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(Icons.home, size: 48, color: AppColors.white),
          const SizedBox(height: 16),
          Text('Hoş geldiniz!', style: AppTextStyles.h2.copyWith(color: AppColors.white), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          authState.when(
            data: (user) {
              if (user != null) {
                return Text(
                  user.displayName ?? user.email, // İsim varsa ismi, yoksa email'i göster
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.white.withOpacity(0.9)),
                  textAlign: TextAlign.center,
                );
              }
              return Text(
                'Kullanıcı bulunamadı',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.white.withOpacity(0.9)),
                textAlign: TextAlign.center,
              );
            },
            loading: () => const CircularProgressIndicator(color: AppColors.white),
            error:
                (error, stack) => Text(
                  'Hata: $error',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white.withOpacity(0.9)),
                  textAlign: TextAlign.center,
                ),
          ),
        ],
      ),
    );
  }
}
