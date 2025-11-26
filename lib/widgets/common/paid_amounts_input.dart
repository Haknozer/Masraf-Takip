import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../inputs/paid_amount_member_item.dart';
import '../inputs/paid_amount_summary.dart';

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
          () => TextEditingController(text: widget.paidAmounts[id]?.toStringAsFixed(2) ?? '0.00'),
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
      _controllers[id] = TextEditingController(text: widget.paidAmounts[id]?.toStringAsFixed(2) ?? '0.00');
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
    final updated = Map<String, double>.from(widget.paidAmounts)..[userId] = amount;
    widget.onChanged(updated);
  }

  double _sumPaid() => widget.paidAmounts.values.fold(0.0, (sum, value) => sum + value);

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
              style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
              return Text('Üyeler yüklenemedi', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error));
            }

            final members = snapshot.data!;
            return Column(
              children: [
                ...members.map((member) {
                  final controller = _controllers[member.id]!;
                  return PaidAmountMemberItem(
                    member: member,
                    controller: controller,
                    onChanged: (value) => _onAmountChanged(member.id, value),
                  );
                }),
                const SizedBox(height: 4),
                PaidAmountSummary(totalPaid: _sumPaid(), targetTotal: widget.totalAmount),
              ],
            );
          },
        ),
      ],
    );
  }
}
