import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../inputs/manual_distribution_member_input.dart';
import '../inputs/manual_distribution_total.dart';

/// Manuel dağılım için input widget'ı
class ManualDistributionInput extends ConsumerStatefulWidget {
  final List<String> memberIds;
  final double totalAmount;
  final Map<String, double> manualAmounts;
  final Function(Map<String, double> amounts) onChanged;

  const ManualDistributionInput({
    super.key,
    required this.memberIds,
    required this.totalAmount,
    required this.manualAmounts,
    required this.onChanged,
  });

  @override
  ConsumerState<ManualDistributionInput> createState() => _ManualDistributionInputState();
}

class _ManualDistributionInputState extends ConsumerState<ManualDistributionInput> {
  final Map<String, TextEditingController> _controllers = {};
  late Future<List<UserModel>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _membersFuture = _getMembers();
  }

  void _initializeControllers() {
    for (final memberId in widget.memberIds) {
      _controllers[memberId] = TextEditingController(
        text: widget.manualAmounts[memberId]?.toStringAsFixed(2) ?? '0.00',
      );
    }
  }

  @override
  void didUpdateWidget(ManualDistributionInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memberIds != widget.memberIds) {
      // Yeni üyeler eklendi veya çıkarıldı
      for (final memberId in oldWidget.memberIds) {
        if (!widget.memberIds.contains(memberId)) {
          _controllers[memberId]?.dispose();
          _controllers.remove(memberId);
        }
      }
      for (final memberId in widget.memberIds) {
        if (!_controllers.containsKey(memberId)) {
          _controllers[memberId] = TextEditingController(
            text: widget.manualAmounts[memberId]?.toStringAsFixed(2) ?? '0.00',
          );
        }
      }
    }
    // Not: Controller text'lerini parent'tan gelen değerlerle güncellemiyoruz
    // çünkü bu focus kaybına neden olur. Kullanıcı girişi controller'da kalır.
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
    for (final memberId in widget.memberIds) {
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
    // Boş string veya sadece nokta/virgül ise 0.0 olarak kabul et
    final trimmedValue = value.trim();
    double amount;
    if (trimmedValue.isEmpty || trimmedValue == '.' || trimmedValue == ',') {
      amount = 0.0;
    } else {
      amount = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    }

    final newAmounts = Map<String, double>.from(widget.manualAmounts);
    newAmounts[memberId] = amount;

    // Focus kaybını önlemek için callback'i bir sonraki frame'de çağır
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onChanged(newAmounts);
      }
    });
  }

  double _calculateTotal() {
    return widget.manualAmounts.values.fold(0.0, (sum, amount) => sum + amount);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: _membersFuture,
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
              return ManualDistributionMemberInput(
                member: member,
                controller: controller!,
                onChanged: (value) => _updateAmount(member.id, value),
              );
            }),
            const SizedBox(height: AppSpacing.textSpacing),
            ManualDistributionTotal(
              total: total,
              targetTotal: widget.totalAmount,
              isValid: isValid,
              difference: difference,
            ),
          ],
        );
      },
    );
  }
}
