import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../screens/groups/qr_scanner_page.dart';

class GroupOptionsDialog extends StatelessWidget {
  final VoidCallback onCreateGroup;
  final VoidCallback onJoinWithCode;

  const GroupOptionsDialog({
    super.key,
    required this.onCreateGroup,
    required this.onJoinWithCode,
  });

  static void show(
    BuildContext context, {
    required VoidCallback onCreateGroup,
    required VoidCallback onJoinWithCode,
  }) {
    showDialog(
      context: context,
      builder:
          (context) => GroupOptionsDialog(
            onCreateGroup: onCreateGroup,
            onJoinWithCode: onJoinWithCode,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Grup İşlemleri', style: AppTextStyles.h2),
            const SizedBox(height: 24),
            // Yeni Grup Oluştur
            ListTile(
              leading: const Icon(Icons.create, color: AppColors.primary),
              title: const Text('Yeni Grup Oluştur'),
              onTap: () {
                Navigator.pop(context);
                onCreateGroup();
              },
            ),
            // QR Kod ile Katıl
            ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
              title: const Text('QR Kod ile Katıl'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const QRScannerPage()));
              },
            ),
            // Kod ile Katıl
            ListTile(
              leading: const Icon(Icons.group_add, color: AppColors.primary),
              title: const Text('Kod ile Katıl'),
              onTap: () {
                Navigator.pop(context);
                onJoinWithCode();
              },
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ],
        ),
      ),
    );
  }
}

