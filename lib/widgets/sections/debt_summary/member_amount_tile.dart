import 'package:flutter/material.dart';
import '../../../constants/app_text_styles.dart';

class MemberAmountTile extends StatelessWidget {
  final String name;
  final double amount;
  final Color color;
  final IconData icon;

  const MemberAmountTile({
    super.key,
    required this.name,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600))),
          Text(
            '${amount.toStringAsFixed(2)} ₺',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

