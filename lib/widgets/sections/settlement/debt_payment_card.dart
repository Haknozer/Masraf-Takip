import 'package:flutter/material.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_text_styles.dart';
import '../../../constants/app_colors.dart';
import '../../../models/debt_model.dart';
import '../../forms/custom_text_field.dart';
import '../../forms/custom_button.dart';

class DebtPaymentCard extends StatelessWidget {
  final DebtBetweenUsers debt;
  final TextEditingController controller;
  final bool isProcessing;
  final bool isCurrentProcessing;
  final Function(String amount) onRecordPayment;

  const DebtPaymentCard({
    super.key,
    required this.debt,
    required this.controller,
    required this.isProcessing,
    required this.isCurrentProcessing,
    required this.onRecordPayment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.textSpacing),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(debt.fromUserName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      'Toplam Borç: ${debt.amount.toStringAsFixed(2)} ₺',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.textSpacing),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: controller,
                    label: 'Ödeme Miktarı (₺)',
                    hint: '0.00',
                    prefixIcon: Icons.currency_lira,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) return null;
                      final amount = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
                      if (amount < 0) return 'Miktar negatif olamaz';
                      if (amount > debt.amount) return 'Miktar borçtan fazla olamaz';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: controller,
                        builder: (context, value, _) {
                          final hasInput = value.text.trim().isNotEmpty;
                          final canSave = hasInput && !isProcessing;
                          // Note: logic regarding !isProcessing was slightly different in original:
                          // !isLoading where isLoading = _isProcessing && _processingUserId == debt.fromUserId;
                          // But button loading state is specific.
                          // In original: final isLoading = _isProcessing && _processingUserId == debt.fromUserId;
                          // final canSave = hasInput && !isLoading;
                          // Here passed isCurrentProcessing which is the isLoading state for this card.
                          // However, usually we disable all if processing something else?
                          // The original logic: canSave = hasInput && !isLoading.
                          // If another card is processing, _isProcessing is true, but isLoading for this card is false.
                          // So originally it allowed clicking if not processing THIS card?
                          // Let's check original: `final isLoading = _isProcessing && _processingUserId == debt.fromUserId;`
                          // `final canSave = hasInput && !isLoading;`
                          // So it allows clicking even if other card is processing? That seems risky if network calls overlap.
                          // But typically `_isProcessing` disables things.
                          // Let's follow the pattern: pass `isLoading` specific to this card.
                          
                          return CustomButton(
                            text: 'Kaydet',
                            onPressed: canSave ? () => onRecordPayment(controller.text) : null,
                            isLoading: isCurrentProcessing,
                            height: 56,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

