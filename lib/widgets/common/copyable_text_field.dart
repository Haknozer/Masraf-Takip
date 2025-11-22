import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import 'copy_button.dart';

/// Kopyalanabilir text field widget'ı
class CopyableTextField extends StatelessWidget {
  final String text;
  final int maxLines;

  const CopyableTextField({
    super.key,
    required this.text,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          CopyButton.icon(text: text, successMessage: 'Link kopyalandı!'),
        ],
      ),
    );
  }
}

