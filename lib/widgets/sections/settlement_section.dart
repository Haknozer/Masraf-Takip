import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';
import '../../models/group_model.dart';
import '../../models/debt_model.dart';
import '../../models/user_model.dart';
import '../../controllers/settlement_controller.dart';
import '../../controllers/group_members_controller.dart';
import '../../providers/auth_provider.dart';
import '../../providers/debt_provider.dart';
import '../../providers/group_provider.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/forms/custom_text_field.dart';
import '../../widgets/forms/custom_button.dart';

/// Hesaplaşma section'ı
class SettlementSection extends ConsumerStatefulWidget {
  final GroupModel group;

  const SettlementSection({super.key, required this.group});

  @override
  ConsumerState<SettlementSection> createState() => _SettlementSectionState();
}

class _SettlementSectionState extends ConsumerState<SettlementSection> {
  final Map<String, TextEditingController> _paymentControllers = {};
  bool _isProcessing = false;

  @override
  void dispose() {
    for (final controller in _paymentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();

    final debtSummaryAsync = ref.watch(groupDebtSummaryProvider(widget.group.id));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Hesaplaşma',
                  style: AppTextStyles.h3,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionMargin),
            debtSummaryAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Hata: $e', style: AppTextStyles.bodyMedium),
              data: (debtSummary) {
                // Bana borcu olan kişileri filtrele
                final debtsOwedToMe = debtSummary.debts
                    .where((debt) => debt.toUserId == currentUser.uid)
                    .toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Borçlar bölümü
                    if (debtsOwedToMe.isNotEmpty) ...[
                      Text(
                        'Bana Borcu Olanlar',
                        style: AppTextStyles.h4,
                      ),
                      const SizedBox(height: AppSpacing.textSpacing),
                      ...debtsOwedToMe.map((debt) => _buildDebtPaymentCard(debt)),
                      const SizedBox(height: AppSpacing.sectionMargin),
                    ] else ...[
                      Text(
                        'Bana borcu olan kimse yok',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.sectionMargin),
                    ],

                    // "Kimseden alacağım yok" bölümü
                    _buildSettlementCheckbox(),
                    const SizedBox(height: AppSpacing.sectionMargin),

                    // Diğer üyelerin durumu
                    _buildOtherMembersStatus(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtPaymentCard(DebtBetweenUsers debt) {
    final controller = _paymentControllers.putIfAbsent(
      debt.fromUserId,
      () => TextEditingController(),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.textSpacing),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
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
                    Text(
                      debt.fromUserName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Toplam Borç: ${debt.amount.toStringAsFixed(2)} ₺',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.textSpacing),
          Row(
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
              const SizedBox(width: 8),
              CustomButton(
                text: 'Kaydet',
                onPressed: _isProcessing
                    ? null
                    : () => _recordPayment(debt.fromUserId, controller.text, debt.amount),
                isLoading: false,
                height: 48,
                width: 100,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementCheckbox() {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();

    final isSettled = widget.group.isUserSettled(currentUser.uid);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSettled ? AppColors.success.withOpacity(0.1) : AppColors.greyLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSettled ? AppColors.success : AppColors.greyLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isSettled,
            onChanged: _isProcessing
                ? null
                : (value) {
                    if (value == true) {
                      _markAsSettled();
                    } else {
                      _unmarkAsSettled();
                    }
                  },
            activeColor: AppColors.success,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kimseden alacağım borç yok',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isSettled)
                  Text(
                    'İşaretlendi',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherMembersStatus() {
    return FutureBuilder<List<UserModel>>(
      future: _getGroupMembers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final members = snapshot.data!;
        final currentUser = ref.read(currentUserProvider);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Üyelerin Durumu',
              style: AppTextStyles.h4,
            ),
            const SizedBox(height: AppSpacing.textSpacing),
            ...members.map((member) {
              final isSettled = widget.group.isUserSettled(member.id);
              final isCurrentUser = currentUser?.uid == member.id;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSettled ? AppColors.success.withOpacity(0.1) : AppColors.greyLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSettled ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isSettled ? AppColors.success : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        member.displayName + (isCurrentUser ? ' (Sen)' : ''),
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isSettled)
                      Text(
                        'İşaretlendi',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                  ],
                ),
              );
            }),
            if (widget.group.isAllMembersSettled) ...[
              const SizedBox(height: AppSpacing.textSpacing),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tüm üyeler hesaplaşmayı tamamladı. Grup kapatıldı ve yeni masraf eklenemez.',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<List<UserModel>> _getGroupMembers() async {
    return await GroupMembersController.getGroupMembers(widget.group);
  }

  Future<void> _recordPayment(String fromUserId, String amountText, double totalDebt) async {
    if (amountText.trim().isEmpty) {
      ErrorSnackBar.showWarning(context, 'Lütfen ödeme miktarı girin');
      return;
    }

    final amount = double.tryParse(amountText.replaceAll(',', '.')) ?? 0.0;
    if (amount <= 0) {
      ErrorSnackBar.showWarning(context, 'Ödeme miktarı 0\'dan büyük olmalıdır');
      return;
    }

    if (amount > totalDebt) {
      ErrorSnackBar.showWarning(context, 'Ödeme miktarı borçtan fazla olamaz');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await SettlementController.recordPayment(
        ref,
        widget.group.id,
        fromUserId,
        amount,
        null,
      );

      if (mounted) {
        ErrorSnackBar.showSuccess(context, 'Ödeme kaydedildi');
        _paymentControllers[fromUserId]?.clear();
        // Borç özetini yenile
        ref.invalidate(groupDebtSummaryProvider(widget.group.id));
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, 'Ödeme kaydedilemedi: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _markAsSettled() async {
    setState(() => _isProcessing = true);

    try {
      await SettlementController.markAsSettled(ref, widget.group.id);

      if (mounted) {
        ErrorSnackBar.showSuccess(context, 'İşaretlendi');
        // Grubu yenile
        ref.invalidate(groupNotifierProvider);
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, 'İşaretlenemedi: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _unmarkAsSettled() async {
    setState(() => _isProcessing = true);

    try {
      await SettlementController.unmarkAsSettled(ref, widget.group.id);

      if (mounted) {
        ErrorSnackBar.showSuccess(context, 'İşaret kaldırıldı');
        // Grubu yenile
        ref.invalidate(groupNotifierProvider);
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, 'İşaret kaldırılamadı: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

