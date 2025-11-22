import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';

/// Resim seçme ve gösterimi için ortak widget
class ImagePickerWidget extends StatelessWidget {
  final XFile? selectedImage;
  final String? currentImageUrl;
  final VoidCallback onImageTap;
  final VoidCallback? onRemoveImage;
  final double size;

  const ImagePickerWidget({
    super.key,
    this.selectedImage,
    this.currentImageUrl,
    required this.onImageTap,
    this.onRemoveImage,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: onImageTap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grey, width: 2, strokeAlign: BorderSide.strokeAlignInside),
              ),
              child: _buildImageContent(),
            ),
          ),
          if (selectedImage != null || currentImageUrl != null)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: onRemoveImage,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: AppColors.white, size: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    if (selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(File(selectedImage!.path), fit: BoxFit.cover),
      );
    }

    if (currentImageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          currentImageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 40, color: AppColors.textSecondary),
                const SizedBox(height: 8),
                Text('Resim Yüklenemedi', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            );
          },
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 40, color: AppColors.textSecondary),
        const SizedBox(height: 8),
        Text('Resim Ekle', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
