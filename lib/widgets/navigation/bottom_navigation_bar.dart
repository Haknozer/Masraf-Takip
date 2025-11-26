import 'package:flutter/material.dart';
import 'items/bottom_nav_item.dart';
import 'items/bottom_nav_item_widget.dart';
import 'custom_fab.dart';

// Export BottomNavItem so it can be used by other files
export 'items/bottom_nav_item.dart';

/// Responsive Bottom Navigation Bar Widget
class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItem> items;
  final double? fabSpacing;
  final VoidCallback? onFabTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.fabSpacing,
    this.onFabTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final iconSize = isSmallScreen ? 20.0 : 24.0;
    final fontSize = isSmallScreen ? 10.0 : 11.0;
    final horizontalPadding = isSmallScreen ? 8.0 : 16.0;
    final spacing = fabSpacing ?? (isSmallScreen ? 50.0 : 60.0);

    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              constraints: BoxConstraints(minHeight: isSmallScreen ? 65 : 70),
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Sol taraftaki item'lar
                  for (int i = 0; i < items.length ~/ 2; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: spacing / 2),
                        child: BottomNavItemWidget(
                          item: items[i],
                          isSelected: currentIndex == items[i].index,
                          onTap: () => onTap(items[i].index),
                          iconSize: iconSize,
                          fontSize: fontSize,
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                    ),
                  // FAB için boş alan
                  SizedBox(width: spacing),
                  // Sağ taraftaki item'lar
                  for (int i = items.length ~/ 2; i < items.length; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: spacing / 2),
                        child: BottomNavItemWidget(
                          item: items[i],
                          isSelected: currentIndex == items[i].index,
                          onTap: () => onTap(items[i].index),
                          iconSize: iconSize,
                          fontSize: fontSize,
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // FAB - Navigation bar'ın üstünde, ortada
            if (onFabTap != null)
              Positioned(top: -30, child: CustomFab(onTap: onFabTap!, isSmallScreen: isSmallScreen)),
          ],
        ),
      ),
    );
  }
}
