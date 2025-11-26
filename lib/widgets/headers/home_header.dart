import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';
import '../forms/custom_button.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback onNewGroupPressed;

  const HomeHeader({super.key, required this.onNewGroupPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sectionPadding,
        AppSpacing.sectionPadding + 8,
        AppSpacing.sectionPadding,
        AppSpacing.sectionPadding,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Masraf Takip',
              style: AppTextStyles.h3.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
            ),
            CustomButton(
              text: 'Yeni Grup',
              onPressed: onNewGroupPressed,
              icon: Icons.add,
              height: 40,
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ],
        ),
      ),
    );
  }
}

