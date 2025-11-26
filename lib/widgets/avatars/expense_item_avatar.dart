import 'package:flutter/material.dart';

class ExpenseItemAvatar extends StatelessWidget {
  final String? imageUrl;
  final IconData icon;
  final Color color;

  const ExpenseItemAvatar({
    super.key,
    required this.imageUrl,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          cacheWidth: 96, // 2x for better quality on high-DPI screens
          cacheHeight: 96,
          errorBuilder: (context, error, stackTrace) => _buildIconAvatar(icon, color),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildIconAvatar(icon, color);
          },
        ),
      );
    }
    return _buildIconAvatar(icon, color);
  }

  Widget _buildIconAvatar(IconData icon, Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color),
    );
  }
}

