import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_text_styles.dart';
import '../../../models/user_model.dart';
import '../../common/image_picker_widget.dart';

class ProfileInfoCard extends StatelessWidget {
  final UserModel user;
  final XFile? pickedImage;
  final VoidCallback onImageTap;
  final VoidCallback onRemoveImage;

  const ProfileInfoCard({
    super.key,
    required this.user,
    required this.pickedImage,
    required this.onImageTap,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ImagePickerWidget(
              selectedImage: pickedImage,
              currentImageUrl: user.photoUrl,
              onImageTap: onImageTap,
              onRemoveImage: onRemoveImage,
              size: 120,
            ),
            const SizedBox(height: AppSpacing.sectionMargin),
            const SizedBox(height: AppSpacing.sectionMargin),
            Column(
              children: [
                Text(user.displayName, style: AppTextStyles.h3),
                const SizedBox(height: 4),
                Text(user.email, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
