import 'package:flutter/material.dart';
import '../../constants/app_text_styles.dart';
import '../../utils/date_utils.dart' as app_date_utils;

class ExpenseItemSubtitle extends StatelessWidget {
  final DateTime date;
  final String payerInfo;
  final int participantCount;

  const ExpenseItemSubtitle({
    super.key,
    required this.date,
    required this.payerInfo,
    required this.participantCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          app_date_utils.AppDateUtils.formatDate(date),
          style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.person, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                payerInfo,
                style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.people, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              '$participantCount',
              style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}

