import 'package:flutter/material.dart';

import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';

class RecentExpensesSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const RecentExpensesSearchBar({super.key, required this.controller, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor = colorScheme.outlineVariant.withOpacity(0.5);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Masraf ara...',
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
            prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
            suffixIcon:
                controller.text.isNotEmpty
                    ? IconButton(icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant), onPressed: onClear)
                    : null,
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: AppTextStyles.bodyMedium.copyWith(color: colorScheme.onSurface),
        ),
      ),
    );
  }
}
