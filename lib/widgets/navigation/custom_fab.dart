import 'package:flutter/material.dart';

class CustomFab extends StatelessWidget {
  final VoidCallback onTap;
  final bool isSmallScreen;

  const CustomFab({super.key, required this.onTap, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    final fabSize = isSmallScreen ? 56.0 : 64.0;
    final iconSize = isSmallScreen ? 26.0 : 30.0;
    final fontSize = isSmallScreen ? 10.0 : 11.0;
    final colorScheme = Theme.of(context).colorScheme;

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
              colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.85)],
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(fabSize / 2),
              child: Icon(Icons.add, color: colorScheme.onPrimary, size: iconSize),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Masraf Ekle',
          style: TextStyle(fontSize: fontSize, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

