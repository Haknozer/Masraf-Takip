import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_text_styles.dart';
import '../../../constants/app_spacing.dart';
import '../../../providers/debt_provider.dart';
import 'debt_payment_card.dart';

class DebtPaymentTab extends ConsumerWidget {
  final String groupId;
  final String currentUserId;
  final Map<String, TextEditingController> paymentControllers;
  final bool isProcessing;
  final String? processingUserId;
  final Function(String fromUserId, String amount, double totalDebt) onRecordPayment;

  const DebtPaymentTab({
    super.key,
    required this.groupId,
    required this.currentUserId,
    required this.paymentControllers,
    required this.isProcessing,
    required this.processingUserId,
    required this.onRecordPayment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtSummaryAsync = ref.watch(groupDebtSummaryProvider(groupId));

    return debtSummaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Hata: $e', style: AppTextStyles.bodyMedium)),
      data: (debtSummary) {
        // Bana borcu olan kişileri filtrele
        final debtsOwedToMe = debtSummary.debts.where((debt) => debt.toUserId == currentUserId).toList();

        if (debtsOwedToMe.isEmpty) {
          return Center(
            child: Text(
              'Bana borcu olan kimse yok',
              style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Bana Borcu Olanlar', style: AppTextStyles.h4),
              const SizedBox(height: AppSpacing.textSpacing),
              ...debtsOwedToMe.map((debt) {
                final controller = paymentControllers.putIfAbsent(debt.fromUserId, () => TextEditingController());
                return DebtPaymentCard(
                  debt: debt,
                  controller: controller,
                  isProcessing: isProcessing,
                  isCurrentProcessing: isProcessing && processingUserId == debt.fromUserId,
                  onRecordPayment: (amount) => onRecordPayment(debt.fromUserId, amount, debt.amount),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

