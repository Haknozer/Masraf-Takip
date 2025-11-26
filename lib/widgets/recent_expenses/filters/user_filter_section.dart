import 'package:flutter/material.dart';
import '../../../constants/app_text_styles.dart';
import '../../../models/user_model.dart';

class UserFilterSection extends StatelessWidget {
  final String? selectedUserId;
  final List<UserModel> groupMembers;
  final ValueChanged<String?> onUserChanged;

  const UserFilterSection({
    super.key,
    required this.selectedUserId,
    required this.groupMembers,
    required this.onUserChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kişi', style: AppTextStyles.label),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: selectedUserId, // value yerine initialValue kullanılıyor
          decoration: InputDecoration(
            hintText: 'Tümü',
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: [
            DropdownMenuItem<String>(value: null, child: Text('Tümü', style: AppTextStyles.bodyMedium)),
            ...groupMembers.map(
              (member) => DropdownMenuItem<String>(
                value: member.id,
                child: Text(member.displayName, style: AppTextStyles.bodyMedium),
              ),
            ),
          ],
          onChanged: onUserChanged,
        ),
      ],
    );
  }
}
