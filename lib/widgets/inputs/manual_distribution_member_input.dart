import 'package:flutter/material.dart';
import '../../constants/app_spacing.dart';
import '../../models/user_model.dart';
import '../../widgets/forms/custom_text_field.dart';

class ManualDistributionMemberInput extends StatelessWidget {
  final UserModel member;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const ManualDistributionMemberInput({
    super.key,
    required this.member,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.textSpacing * 2),
      child: CustomTextField(
        controller: controller,
        label: member.displayName,
        hint: '0.00',
        prefixIcon: Icons.person,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: onChanged,
        validator: (value) {
          final amount = double.tryParse(value ?? '') ?? 0.0;
          if (amount < 0) {
            return 'Negatif olamaz';
          }
          return null;
        },
      ),
    );
  }
}

