import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class ExpenseItemTrailing extends StatelessWidget {
  final double amount;
  final bool showEditIcon;
  final bool showDeleteIcon;
  final bool canDelete;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ExpenseItemTrailing({
    super.key,
    required this.amount,
    required this.showEditIcon,
    required this.showDeleteIcon,
    required this.canDelete,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${amount.toStringAsFixed(2)} ₺',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
        ),
        if (showEditIcon && onTap != null) ...[
          const SizedBox(width: 8),
          Icon(Icons.edit, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ],
        if (showDeleteIcon && onDelete != null && canDelete) ...[
          const SizedBox(width: 8),
          GestureDetector(onTap: onDelete, child: Icon(Icons.delete_outline, size: 18, color: AppColors.error)),
        ],
      ],
    );
  }
}

