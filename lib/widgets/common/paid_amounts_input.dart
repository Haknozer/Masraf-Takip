import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../forms/custom_text_field.dart';

/// Bir masrafta kim ne kadar ödedi bilgisini girmek için widget
class PaidAmountsInput extends ConsumerStatefulWidget {
  final List<String> memberIds;
  final double totalAmount;
  final Map<String, double> paidAmounts;
  final ValueChanged<Map<String, double>> onChanged;

  const PaidAmountsInput({
    super.key,
    required this.memberIds,
    required this.totalAmount,
    required this.paidAmounts,
    required this.onChanged,
  });

  @override
  ConsumerState<PaidAmountsInput> createState() => _PaidAmountsInputState();
}

class _PaidAmountsInputState extends ConsumerState<PaidAmountsInput> {
  final Map<String, TextEditingController> _controllers = {};
  late Future<List<UserModel>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _membersFuture = _fetchMembers();
  }

  @override
  void didUpdateWidget(PaidAmountsInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memberIds != widget.memberIds) {
      for (final id in oldWidget.memberIds) {
        if (!widget.memberIds.contains(id)) {
          _controllers[id]?.dispose();
          _controllers.remove(id);
        }
      }
      for (final id in widget.memberIds) {
        _controllers.putIfAbsent(
          id,
          () => TextEditingController(
            text: widget.paidAmounts[id]?.toStringAsFixed(2) ?? '0.00',
          ),
        );
      }
      _membersFuture = _fetchMembers();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initControllers() {
    for (final id in widget.memberIds) {
      _controllers[id] = TextEditingController(
        text: widget.paidAmounts[id]?.toStringAsFixed(2) ?? '0.00',
      );
    }
  }

  Future<List<UserModel>> _fetchMembers() async {
    final users = <UserModel>[];
    for (final id in widget.memberIds) {
      try {
        final doc = await FirebaseService.getDocumentSnapshot('users/$id');
        if (doc.exists) {
          users.add(UserModel.fromJson(doc.data() as Map<String, dynamic>));
        }
      } catch (_) {
        continue;
      }
    }
    return users;
  }

  void _onAmountChanged(String userId, String value) {
    final sanitized = value.trim().isEmpty ? '0' : value;
    final amount = double.tryParse(sanitized.replaceAll(',', '.')) ?? 0.0;
    final updated = Map<String, double>.from(widget.paidAmounts)
      ..[userId] = amount;
    widget.onChanged(updated);
  }

  double _sumPaid() =>
      widget.paidAmounts.values.fold(0.0, (sum, value) => sum + value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Kim ne kadar ödedi?', style: AppTextStyles.label),
            Text(
              'Toplam ${widget.totalAmount.toStringAsFixed(2)} ₺',
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.textSpacing),
        FutureBuilder<List<UserModel>>(
          future: _membersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.hasError) {
              return Text(
                'Üyeler yüklenemedi',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              );
            }

            final members = snapshot.data!;
            return Column(
              children: [
                ...members.map(
                  (member) {
                    final controller = _controllers[member.id]!;
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppSpacing.textSpacing * 2,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                Theme.of(context).colorScheme.surfaceVariant,
                            backgroundImage: member.photoUrl != null
                                ? NetworkImage(member.photoUrl!)
                                : null,
                            child: member.photoUrl == null
                                ? Text(
                                    member.displayName.isNotEmpty
                                        ? member.displayName[0].toUpperCase()
                                        : '?',
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.displayName,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  member.email,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: CustomTextField(
                              controller: controller,
                              label: 'Ödenen',
                              hint: '0.00',
                              prefixIcon: Icons.currency_lira,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (value) =>
                                  _onAmountChanged(member.id, value),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                _buildSummary(context),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    final totalPaid = _sumPaid();
    final difference = widget.totalAmount - totalPaid;
    final isValid = difference.abs() < 0.01;
    final color = isValid ? AppColors.success : AppColors.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ödenen Toplam',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${totalPaid.toStringAsFixed(2)} ₺',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          if (!isValid)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                difference > 0
                    ? 'Eksik: ${difference.toStringAsFixed(2)} ₺'
                    : 'Fazla: ${(-difference).toStringAsFixed(2)} ₺',
                style: AppTextStyles.bodySmall.copyWith(color: color),
              ),
            ),
        ],
      ),
    );
  }
}

