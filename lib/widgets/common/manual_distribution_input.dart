import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../../widgets/forms/custom_text_field.dart';

/// Manuel dağılım için input widget'ı
class ManualDistributionInput extends ConsumerStatefulWidget {
  final List<String> selectedMemberIds;
  final double totalAmount;
  final Map<String, double> memberAmounts;
  final Function(Map<String, double> amounts) onAmountsChanged;

  const ManualDistributionInput({
    super.key,
    required this.selectedMemberIds,
    required this.totalAmount,
    required this.memberAmounts,
    required this.onAmountsChanged,
  });

  @override
  ConsumerState<ManualDistributionInput> createState() => _ManualDistributionInputState();
}

class _ManualDistributionInputState extends ConsumerState<ManualDistributionInput> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (final memberId in widget.selectedMemberIds) {
      _controllers[memberId] = TextEditingController(
        text: widget.memberAmounts[memberId]?.toStringAsFixed(2) ?? '0.00',
      );
    }
  }

  @override
  void didUpdateWidget(ManualDistributionInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMemberIds != widget.selectedMemberIds) {
      // Yeni üyeler eklendi veya çıkarıldı
      for (final memberId in oldWidget.selectedMemberIds) {
        if (!widget.selectedMemberIds.contains(memberId)) {
          _controllers[memberId]?.dispose();
          _controllers.remove(memberId);
        }
      }
      for (final memberId in widget.selectedMemberIds) {
        if (!_controllers.containsKey(memberId)) {
          _controllers[memberId] = TextEditingController(
            text: widget.memberAmounts[memberId]?.toStringAsFixed(2) ?? '0.00',
          );
        }
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<List<UserModel>> _getMembers() async {
    final members = <UserModel>[];
    for (final memberId in widget.selectedMemberIds) {
      try {
        final userDoc = await FirebaseService.getDocumentSnapshot('users/$memberId');
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          members.add(UserModel.fromJson(data));
        }
      } catch (e) {
        // Hata durumunda devam et
      }
    }
    return members;
  }

  void _updateAmount(String memberId, String value) {
    final amount = double.tryParse(value) ?? 0.0;
    final newAmounts = Map<String, double>.from(widget.memberAmounts);
    newAmounts[memberId] = amount;
    widget.onAmountsChanged(newAmounts);
  }

  double _calculateTotal() {
    return widget.memberAmounts.values.fold(0.0, (sum, amount) => sum + amount);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: _getMembers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Text('Üyeler yüklenemedi');
        }

        final members = snapshot.data!;
        final total = _calculateTotal();
        final difference = widget.totalAmount - total;
        final isValid = (difference.abs() < 0.01); // 0.01 TL tolerans

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manuel Dağılım', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.textSpacing),
            ...members.map((member) {
              final controller = _controllers[member.id];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.textSpacing * 2),
                child: CustomTextField(
                  controller: controller!,
                  label: member.displayName,
                  hint: '0.00',
                  prefixIcon: Icons.person,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => _updateAmount(member.id, value),
                  validator: (value) {
                    final amount = double.tryParse(value ?? '') ?? 0.0;
                    if (amount < 0) {
                      return 'Negatif olamaz';
                    }
                    return null;
                  },
                ),
              );
            }),
            const SizedBox(height: AppSpacing.textSpacing),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isValid ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isValid ? AppColors.success : AppColors.error,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Toplam:',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${total.toStringAsFixed(2)} TL / ${widget.totalAmount.toStringAsFixed(2)} TL',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isValid ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (!isValid)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  difference > 0
                      ? 'Eksik: ${difference.toStringAsFixed(2)} TL'
                      : 'Fazla: ${(-difference).toStringAsFixed(2)} TL',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                ),
              ),
          ],
        );
      },
    );
  }
}

