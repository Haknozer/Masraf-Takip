import 'package:flutter/material.dart';
import '../../../constants/app_text_styles.dart';

class RecentExpensesSearchBar extends StatelessWidget {
  final TextEditingController controller;

  const RecentExpensesSearchBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor = colorScheme.outlineVariant.withValues(alpha: 0.5);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, child) {
            return TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Masraf ara...',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                prefixIcon: Icon(Icons.search, size: 18, color: colorScheme.onSurfaceVariant),
                suffixIcon:
                    value.text.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.clear, size: 18, color: colorScheme.onSurfaceVariant),
                          onPressed: controller.clear,
                        )
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: AppTextStyles.bodySmall,
            );
          },
        ),
      ),
    );
  }
}
