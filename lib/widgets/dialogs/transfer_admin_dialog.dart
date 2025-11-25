import 'package:flutter/material.dart';
import '../../constants/app_text_styles.dart';
import '../../models/user_model.dart';

/// Admin yetkisi devretme onay dialogu
class TransferAdminDialog extends StatelessWidget {
  final UserModel member;

  const TransferAdminDialog({
    super.key,
    required this.member,
  });

  static Future<bool?> show(
    BuildContext context, {
    required UserModel member,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => TransferAdminDialog(member: member),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Admin Yetkisi Ver',
        style: AppTextStyles.h3,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${member.displayName} kullanıcısına admin yetkisi vermek istediğinize emin misiniz?',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Bu işlem sonrasında ${member.displayName} admin yetkisine sahip olacaktır. Sizin admin yetkiniz korunacaktır.',
            style: AppTextStyles.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'İptal',
            style: AppTextStyles.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          child: const Text('Yetki Ver'),
        ),
      ],
    );
  }
}

