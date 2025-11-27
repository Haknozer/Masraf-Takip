import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import 'member_breakdown_data.dart';
import 'member_amount_tile.dart';

class MemberBreakdownSection extends StatelessWidget {
  final MemberBreakdownData data;

  const MemberBreakdownSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.receivables.isNotEmpty) ...[
          Text(
            'Alacaklı olduğun kişiler',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...data.receivables.map(
            (item) => MemberAmountTile(
              name: item.name,
              amount: item.amount,
              color: AppColors.success,
              icon: Icons.call_made,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (data.payables.isNotEmpty) ...[
          Text('Borçlu olduğun kişiler', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...data.payables.map(
            (item) => MemberAmountTile(
              name: item.name,
              amount: item.amount,
              color: AppColors.error,
              icon: Icons.call_received,
            ),
          ),
        ],
      ],
    );
  }
}

