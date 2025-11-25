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
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.grey, width: 2, strokeAlign: BorderSide.strokeAlignInside),
              ),
              child: ClipOval(child: _buildImageContent()),
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
          Positioned(
            bottom: 4,
            right: 8,
            child: GestureDetector(
              onTap: onImageTap,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
                child: const Icon(Icons.photo_camera, size: 16, color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    if (selectedImage != null) {
      return Image.file(File(selectedImage!.path), fit: BoxFit.cover);
    }

    if (currentImageUrl != null) {
      return Image.network(
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
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.person, size: 48, color: AppColors.textSecondary),
      ],
    );
  }
}
