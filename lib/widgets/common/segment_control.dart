import 'package:flutter/material.dart';
import '../../constants/app_text_styles.dart';

class SegmentControl extends StatelessWidget {
  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onSegmentChanged;

  const SegmentControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onSegmentChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children:
            segments.asMap().entries.map((entry) {
              final index = entry.key;
              final label = entry.value;
              final isSelected = index == selectedIndex;
              final isFirst = index == 0;
              final isLast = index == segments.length - 1;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onSegmentChanged(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? colorScheme.surface : Colors.transparent,
                      borderRadius: BorderRadius.only(
                        topLeft: isFirst ? const Radius.circular(8) : Radius.zero,
                        bottomLeft: isFirst ? const Radius.circular(8) : Radius.zero,
                        topRight: isLast ? const Radius.circular(8) : Radius.zero,
                        bottomRight: isLast ? const Radius.circular(8) : Radius.zero,
                      ),
                      border:
                          isSelected ? Border.all(color: colorScheme.primary.withValues(alpha: 0.4), width: 1) : null,
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
