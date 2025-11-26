import 'package:flutter/material.dart';
import '../../../constants/app_text_styles.dart';
import 'bottom_nav_item.dart';

class BottomNavItemWidget extends StatelessWidget {
  final BottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final double iconSize;
  final double fontSize;
  final bool isSmallScreen;

  const BottomNavItemWidget({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.iconSize,
    required this.fontSize,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final horizontalPadding = isSmallScreen ? 8.0 : 16.0;
    
    // FAB alanında border gösterme - overflow'u önlemek için
    final shouldShowBorder = isSelected;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 4),
        margin: EdgeInsets.symmetric(
          // FAB alanına yakınsa border'ı içeride tut
          horizontal: isSelected ? 4 : 0,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: shouldShowBorder ? Border.all(color: colorScheme.primary, width: 1.5) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: iconSize,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: fontSize,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

