import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';

class RecentExpensesSection extends StatelessWidget {
  const RecentExpensesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Son Masraflar', style: AppTextStyles.h3),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              children: [
                _buildExpenseItem(Icons.receipt, 'Kahve', 'Starbucks', '₺25.50'),
                const Divider(),
                _buildExpenseItem(Icons.restaurant, 'Yemek', 'Pizza Palace', '₺120.00'),
                const Divider(),
                _buildExpenseItem(Icons.local_gas_station, 'Benzin', 'Shell', '₺300.00'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseItem(IconData icon, String title, String subtitle, String amount) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(amount, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success)),
    );
  }
}
