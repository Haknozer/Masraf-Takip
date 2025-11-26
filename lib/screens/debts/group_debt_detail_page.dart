import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/debt_model.dart';
import '../../providers/debt_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/async_value_builder.dart';
import '../../widgets/common/loading_card.dart';
import '../../widgets/cards/error_card.dart';
import '../../widgets/cards/debt_summary_item.dart';
import '../../widgets/cards/debt_detail_card.dart';

/// Grup bazında detaylı borç sayfası
class GroupDebtDetailPage extends ConsumerWidget {
  final String groupId;

  const GroupDebtDetailPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupDebtState = ref.watch(groupDebtSummaryProvider(groupId));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Grup Borç Detayları'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: AsyncValueBuilder<GroupDebtSummary>(
        value: groupDebtState,
        dataBuilder: (context, summary) {
          if (summary.debts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet, 
                    size: 64, 
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bu grupta borç/alacak yok',
                    style: AppTextStyles.h4.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grup Özeti
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(summary.groupName, style: AppTextStyles.h4),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DebtSummaryItem(
                                label: 'Borç',
                                amount: summary.totalOwed,
                                color: AppColors.error,
                                icon: Icons.arrow_downward,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DebtSummaryItem(
                                label: 'Alacak',
                                amount: summary.totalOwing,
                                color: AppColors.success,
                                icon: Icons.arrow_upward,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Borç Detayları
                Text('Borç Detayları', style: AppTextStyles.h3),
                const SizedBox(height: 12),
                ...summary.debts.map((debt) {
                  final currentUser = ref.read(currentUserProvider);
                  return DebtDetailCard(debt: debt, currentUserId: currentUser?.uid ?? '');
                }),
              ],
            ),
          );
        },
        loadingBuilder: (context) => const LoadingCard(),
        errorBuilder: (context, error, stack) => const ErrorCard(error: 'Borç bilgileri yüklenemedi'),
      ),
    );
  }
}

