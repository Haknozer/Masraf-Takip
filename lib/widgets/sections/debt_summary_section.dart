import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/debt_model.dart';
import '../../providers/debt_provider.dart';
import '../../widgets/common/async_value_builder.dart';
import '../../screens/debts/debt_detail_page.dart';

/// Ana sayfada gösterilecek borç özeti widget'ı
class DebtSummarySection extends ConsumerWidget {
  const DebtSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtSummaryState = ref.watch(userDebtSummaryProvider);

    return AsyncValueBuilder<UserDebtSummary>(
      value: debtSummaryState,
      dataBuilder: (context, summary) {
        final hasDebts = summary.totalOwed > 0 || summary.totalOwing > 0;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const DebtDetailPage()));
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [AppColors.primary.withValues(alpha: 0.05), AppColors.primary.withValues(alpha: 0.02)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Borç Özeti', style: AppTextStyles.h4),
                              if (!hasDebts)
                                Text(
                                  'Henüz borç/alacak yok',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary),
                      ),
                    ],
                  ),
                  if (hasDebts) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _DebtSummaryItem(
                            label: 'Borçlu',
                            amount: summary.totalOwed,
                            color: AppColors.error,
                            icon: Icons.arrow_downward,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(0.5),
                          ),
                        ),
                        Expanded(
                          child: _DebtSummaryItem(
                            label: 'Alacaklı',
                            amount: summary.totalOwing,
                            color: AppColors.success,
                            icon: Icons.arrow_upward,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            summary.netAmount == 0
                                ? Theme.of(context).colorScheme.surfaceContainerHighest
                                : (summary.netAmount > 0 ? AppColors.success : AppColors.error).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              summary.netAmount == 0
                                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                                  : (summary.netAmount > 0 ? AppColors.success : AppColors.error).withValues(
                                    alpha: 0.3,
                                  ),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                summary.netAmount == 0
                                    ? Icons.check_circle_outline
                                    : summary.netAmount > 0
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                color:
                                    summary.netAmount == 0
                                        ? Theme.of(context).colorScheme.onSurfaceVariant
                                        : summary.netAmount > 0
                                        ? AppColors.success
                                        : AppColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Net Durum',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      summary.netAmount == 0
                                          ? Theme.of(context).colorScheme.onSurfaceVariant
                                          : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            summary.netAmount == 0
                                ? '0.00 ₺'
                                : '${summary.netAmount > 0 ? '+' : ''}${summary.netAmount.toStringAsFixed(2)} ₺',
                            style: AppTextStyles.h4.copyWith(
                              color:
                                  summary.netAmount == 0
                                      ? Theme.of(context).colorScheme.onSurfaceVariant
                                      : summary.netAmount > 0
                                      ? AppColors.success
                                      : AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Detaylara Gir',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.arrow_forward, size: 18, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Detaylara Gir',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.arrow_forward, size: 18, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
      loadingBuilder:
          (context) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Text('Borç özeti yükleniyor...', style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
          ),
      errorBuilder:
          (context, error, stack) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Borç özeti yüklenemedi',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

class _DebtSummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _DebtSummaryItem({required this.label, required this.amount, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${amount.toStringAsFixed(2)} ₺',
            style: AppTextStyles.h4.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
