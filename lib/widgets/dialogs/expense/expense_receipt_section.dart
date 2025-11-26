import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_text_styles.dart';
import '../../../constants/app_colors.dart';

class ExpenseReceiptSection extends StatelessWidget {
  final XFile? receiptImage;
  final String? imageUrl;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final Function(ImageProvider) onShowPreview;
  final bool canEdit;

  const ExpenseReceiptSection({
    super.key,
    this.receiptImage,
    this.imageUrl,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onShowPreview,
    this.canEdit = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasNewImage = receiptImage != null;
    final hasExistingImage = imageUrl != null && imageUrl!.isNotEmpty;

    if (!canEdit && !hasNewImage && !hasExistingImage) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fiş / Fotoğraf (Opsiyonel)', style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.textSpacing),
        if (hasNewImage) ...[
          Stack(
            children: [
              GestureDetector(
                onTap: () => onShowPreview(Image.file(File(receiptImage!.path)).image),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(receiptImage!.path),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (canEdit)
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: colorScheme.surface,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      color: colorScheme.error,
                      onPressed: onRemoveImage,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ] else if (hasExistingImage) ...[
          Stack(
            children: [
              GestureDetector(
                onTap: () => onShowPreview(Image.network(imageUrl!).image),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(imageUrl!, height: 180, width: double.infinity, fit: BoxFit.cover),
                ),
              ),
              if (canEdit)
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: colorScheme.surface,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      color: colorScheme.error,
                      onPressed: onRemoveImage,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ] else if (!canEdit) ...[
          Text('Fotoğraf eklenmemiş', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
        if (canEdit)
          OutlinedButton.icon(
            onPressed: onPickImage,
            icon: const Icon(Icons.photo_camera),
            label: Text(hasNewImage || hasExistingImage ? 'Fotoğrafı Değiştir' : 'Fotoğraf Ekle'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
      ],
    );
  }
}
