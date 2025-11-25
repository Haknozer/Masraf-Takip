import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

/// Bottom Navigation Bar Item Model
class BottomNavItem {
  final IconData icon;
  final String label;
  final int index;

  const BottomNavItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}

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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              constraints: BoxConstraints(minHeight: isSmallScreen ? 65 : 70),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 6,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Sol taraftaki item'lar
                  for (int i = 0; i < items.length ~/ 2; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: spacing / 2),
                        child: _buildNavItem(
                          context: context,
                          item: items[i],
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
                        child: _buildNavItem(
                          context: context,
                          item: items[i],
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
              Positioned(
                top: -30,
                child: _buildFloatingActionButton(context, isSmallScreen),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required BottomNavItem item,
    required double iconSize,
    required double fontSize,
    required bool isSmallScreen,
  }) {
    final isSelected = currentIndex == item.index;
    final horizontalPadding = isSmallScreen ? 8.0 : 16.0;

    // FAB alanında border gösterme - overflow'u önlemek için
    final shouldShowBorder = isSelected;

    return GestureDetector(
      onTap: () => onTap(item.index),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 4,
        ),
        margin: EdgeInsets.symmetric(
          // FAB alanına yakınsa border'ı içeride tut
          horizontal: isSelected ? 4 : 0,
        ),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border:
              shouldShowBorder
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: iconSize,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
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

  Widget _buildFloatingActionButton(BuildContext context, bool isSmallScreen) {
    final fabSize = isSmallScreen ? 56.0 : 64.0;
    final iconSize = isSmallScreen ? 26.0 : 30.0;
    final fontSize = isSmallScreen ? 10.0 : 11.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: fabSize,
          height: fabSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onFabTap,
              borderRadius: BorderRadius.circular(fabSize / 2),
              child: Icon(Icons.add, color: AppColors.white, size: iconSize),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Harcama Ekle',
          style: TextStyle(
            fontSize: fontSize,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
