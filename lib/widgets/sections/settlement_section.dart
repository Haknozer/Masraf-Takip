import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';
import '../../models/group_model.dart';
import '../../controllers/settlement_controller.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/debt_provider.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/common/segment_control.dart';
import 'settlement/debt_payment_tab.dart';
import 'settlement/group_closure_tab.dart';

/// Hesaplaşma section'ı
class SettlementSection extends ConsumerStatefulWidget {
  final GroupModel group;

  const SettlementSection({super.key, required this.group});

  @override
  ConsumerState<SettlementSection> createState() => _SettlementSectionState();
}

class _SettlementSectionState extends ConsumerState<SettlementSection> {
  final Map<String, TextEditingController> _paymentControllers = {};
  int _selectedTab = 0; // 0: Borç Ödeme, 1: Grup Kapatma
  bool _isProcessing = false;
  String? _processingUserId;

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
                Text('Hesaplaşma', style: AppTextStyles.h3),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionMargin),
            // Tab Control
            SegmentControl(
              segments: const ['Borç Ödeme', 'Grup Kapatma'],
              selectedIndex: _selectedTab,
              onSegmentChanged: (index) {
                setState(() {
                  _selectedTab = index;
                });
              },
            ),
            const SizedBox(height: AppSpacing.sectionMargin),
            // Tab Content
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 500),
              child:
                  _selectedTab == 0
                      ? DebtPaymentTab(
                        groupId: widget.group.id,
                        currentUserId: currentUser.uid,
                        paymentControllers: _paymentControllers,
                        isProcessing: _isProcessing,
                        processingUserId: _processingUserId,
                        onRecordPayment: _recordPayment,
                      )
                      : GroupClosureTab(
                        group: widget.group,
                        currentUserId: currentUser.uid,
                        isProcessing: _isProcessing,
                        onMarkAsSettled: _markAsSettled,
                        onUnmarkAsSettled: _unmarkAsSettled,
                      ),
            ),
          ],
        ),
      ),
    );
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

    setState(() {
      _isProcessing = true;
      _processingUserId = fromUserId;
    });

    try {
      await SettlementController.recordPayment(ref, widget.group.id, fromUserId, amount, null);

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
        setState(() {
          _isProcessing = false;
          _processingUserId = null;
        });
      }
    }
  }

  Future<void> _markAsSettled() async {
    // İşaretleme sonrası tüm üyeler işaretlenmiş olacak mı kontrol et
    final willBeAllSettled = widget.group.settledUserIds.length + 1 == widget.group.memberIds.length;

    setState(() => _isProcessing = true);

    try {
      await SettlementController.markAsSettled(ref, widget.group.id);

      if (mounted) {
        ErrorSnackBar.showSuccess(context, 'İşaretlendi');
        // Grubu yenile
        ref.invalidate(groupProvider(widget.group.id));

        // Eğer bu işaretleme ile tüm üyeler işaretlenmiş olduysa ve grup aktifse, kapatma dialog'u göster
        if (willBeAllSettled && widget.group.isActive) {
          // Kısa bir gecikme ile dialog göster (grup güncellemesinin tamamlanması için)
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            _showCloseGroupDialog();
          }
        }
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
        ref.invalidate(groupProvider(widget.group.id));
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

  Future<void> _showCloseGroupDialog() async {
    final shouldClose = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text('Grup Kapatma', style: AppTextStyles.h3)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tüm üyeler hesaplaşmayı tamamladı.', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 8),
                Text(
                  'Bu grup kapanıyor, emin misiniz?',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Grup kapandıktan sonra yeni masraf eklenemez.',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Hayır',
                  style: AppTextStyles.buttonMedium.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Evet'),
              ),
            ],
          ),
    );

    if (shouldClose == true && mounted) {
      await _closeGroup();
    }
  }

  Future<void> _closeGroup() async {
    setState(() => _isProcessing = true);

    try {
      await SettlementController.closeGroup(ref, widget.group.id);

      if (mounted) {
        ErrorSnackBar.showSuccess(context, 'Grup kapatıldı');
        // Grubu yenile
        ref.invalidate(groupProvider(widget.group.id));
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, 'Grup kapatılamadı: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
