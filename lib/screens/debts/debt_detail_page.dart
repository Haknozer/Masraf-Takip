import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/debt_model.dart';
import '../../providers/debt_provider.dart';
import '../../widgets/common/async_value_builder.dart';
import '../../widgets/common/loading_card.dart';
import '../../widgets/cards/error_card.dart';
import 'group_debt_detail_page.dart';
import '../../widgets/cards/debt_general_summary_card.dart';
import '../../widgets/cards/debt_group_card.dart';

class DebtDetailPage extends ConsumerWidget {
  const DebtDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtSummaryState = ref.watch(userDebtSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Borç Detayları'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: AsyncValueBuilder<UserDebtSummary>(
        value: debtSummaryState,
        dataBuilder: (context, summary) {
          if (summary.groupSummaries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text('Henüz borç/alacak yok', style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Genel Özet
                DebtGeneralSummaryCard(summary: summary),
                const SizedBox(height: 24),
                // Grup Bazında Detaylar
                Text('Grup Bazında Detaylar', style: AppTextStyles.h3),
                const SizedBox(height: 12),
                ...summary.groupSummaries.map((groupSummary) {
                  return DebtGroupCard(
                    groupSummary: groupSummary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => GroupDebtDetailPage(groupId: groupSummary.groupId)),
                      );
                    },
                  );
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
