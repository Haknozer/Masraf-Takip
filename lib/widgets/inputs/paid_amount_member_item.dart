import 'package:flutter/material.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../widgets/forms/custom_text_field.dart';

class PaidAmountMemberItem extends StatelessWidget {
  final UserModel member;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const PaidAmountMemberItem({
    super.key,
    required this.member,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.textSpacing * 2),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            backgroundImage: member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
            child:
                member.photoUrl == null
                    ? Text(member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?')
                    : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  member.email,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

