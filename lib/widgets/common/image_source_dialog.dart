import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';

/// Resim kaynağı seçme dialog'u
class ImageSourceDialog extends StatelessWidget {
  final bool showRemoveOption;

  const ImageSourceDialog({super.key, this.showRemoveOption = false});

  static Future<ImageSource?> show(BuildContext context, {bool showRemoveOption = false}) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => ImageSourceDialog(showRemoveOption: showRemoveOption),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Galeriden Seç'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Kameradan Çek'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          if (showRemoveOption)
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Resmi Kaldır', style: TextStyle(color: AppColors.error)),
              onTap: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}
