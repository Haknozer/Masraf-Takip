import 'package:flutter/material.dart';
import '../../constants/app_text_styles.dart';
import '../../models/user_model.dart';

class MemberSelectorItem extends StatelessWidget {
  final UserModel member;
  final bool isSelected;
  final VoidCallback onTap;

  const MemberSelectorItem({
    super.key,
    required this.member,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final unselectedBg = colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
    final unselectedBorder = colorScheme.outlineVariant.withValues(alpha: 0.5);
    final unselectedText = colorScheme.onSurfaceVariant;
    final selectedColor = colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor.withValues(alpha: 0.15) : unselectedBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? selectedColor : unselectedBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              if (isSelected)
                Icon(Icons.check_circle, color: selectedColor, size: 20)
              else
                Icon(Icons.circle_outlined, color: unselectedText, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  member.displayName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? selectedColor : unselectedText,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

