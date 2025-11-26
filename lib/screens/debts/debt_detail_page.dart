import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/expense_categories.dart';
import '../../models/debt_model.dart';
import '../../providers/debt_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/async_value_builder.dart';
import '../../widgets/common/loading_card.dart';
import '../../widgets/cards/error_card.dart';
import '../../utils/date_utils.dart' as date_utils_helper;

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
                _GeneralSummaryCard(summary: summary),
                const SizedBox(height: 24),
                // Grup Bazında Detaylar
                Text('Grup Bazında Detaylar', style: AppTextStyles.h3),
                const SizedBox(height: 12),
                ...summary.groupSummaries.map((groupSummary) {
                  return _GroupDebtCard(
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

class _GeneralSummaryCard extends StatelessWidget {
  final UserDebtSummary summary;

  const _GeneralSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Genel Özet', style: AppTextStyles.h4),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: 'Toplam Borç',
                    amount: summary.totalOwed,
                    color: AppColors.error,
                    icon: Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryItem(
                    label: 'Toplam Alacak',
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
                color: (summary.netAmount > 0 ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: summary.netAmount > 0 ? AppColors.success : AppColors.error, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Net Durum', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        summary.netAmount > 0 ? 'Alacaklısınız' : 'Borçlusunuz',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Text(
                    '${summary.netAmount > 0 ? '+' : ''}${summary.netAmount.toStringAsFixed(2)} ₺',
                    style: AppTextStyles.h3.copyWith(
                      color: summary.netAmount > 0 ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryItem({required this.label, required this.amount, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${amount.toStringAsFixed(2)} ₺',
            style: AppTextStyles.h4.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _GroupDebtCard extends StatelessWidget {
  final GroupDebtSummary groupSummary;
  final VoidCallback onTap;

  const _GroupDebtCard({required this.groupSummary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(groupSummary.groupName, style: AppTextStyles.h4)),
                  Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _GroupSummaryItem(label: 'Borç', amount: groupSummary.totalOwed, color: AppColors.error),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GroupSummaryItem(
                      label: 'Alacak',
                      amount: groupSummary.totalOwing,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              if (groupSummary.netAmount != 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (groupSummary.netAmount > 0 ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Net', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        '${groupSummary.netAmount > 0 ? '+' : ''}${groupSummary.netAmount.toStringAsFixed(2)} ₺',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: groupSummary.netAmount > 0 ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupSummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _GroupSummaryItem({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(
          '${amount.toStringAsFixed(2)} ₺',
          style: AppTextStyles.bodyLarge.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// Grup bazında detaylı borç sayfası
class GroupDebtDetailPage extends ConsumerWidget {
  final String groupId;

  const GroupDebtDetailPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupDebtState = ref.watch(groupDebtSummaryProvider(groupId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grup Borç Detayları'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: AsyncValueBuilder<GroupDebtSummary>(
        value: groupDebtState,
        dataBuilder: (context, summary) {
          if (summary.debts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text('Bu grupta borç/alacak yok', style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary)),
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
                              child: _SummaryItem(
                                label: 'Borç',
                                amount: summary.totalOwed,
                                color: AppColors.error,
                                icon: Icons.arrow_downward,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _SummaryItem(
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
                  return _DebtDetailCard(debt: debt, currentUserId: currentUser?.uid ?? '');
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

class _DebtDetailCard extends StatelessWidget {
  final DebtBetweenUsers debt;
  final String currentUserId;

  const _DebtDetailCard({required this.debt, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    // Kullanıcı borçlu mu? (fromUserId == currentUserId ise borçlu)
    final isOwed = debt.fromUserId == currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(
              isOwed ? Icons.arrow_downward : Icons.arrow_upward,
              color: isOwed ? AppColors.error : AppColors.success,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isOwed ? '${debt.toUserName}\'a borçlusunuz' : '${debt.fromUserName} size borçlu',
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${debt.amount.toStringAsFixed(2)} ₺',
            style: AppTextStyles.h4.copyWith(
              color: isOwed ? AppColors.error : AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masraf Detayları',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                ...debt.details.map((detail) => _DebtDetailItem(detail: detail)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtDetailItem extends StatelessWidget {
  final DebtDetail detail;

  const _DebtDetailItem({required this.detail});

  @override
  Widget build(BuildContext context) {
    final category = ExpenseCategories.getById(detail.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.greyLight, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (category?.color ?? AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(category?.icon ?? Icons.receipt, color: category?.color ?? AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.expenseDescription, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  date_utils_helper.AppDateUtils.formatDate(detail.date),
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '${detail.amount.toStringAsFixed(2)} ₺',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
