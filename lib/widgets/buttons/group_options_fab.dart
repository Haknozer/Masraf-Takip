import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../screens/groups/create_group_page.dart';
import '../../screens/groups/group_list_page.dart';
import '../../screens/groups/qr_scanner_page.dart';

class GroupOptionsFAB extends StatelessWidget {
  const GroupOptionsFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showGroupOptions(context),
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.add, color: AppColors.white),
    );
  }

  void _showGroupOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Grup İşlemleri', style: AppTextStyles.h3),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.group, color: AppColors.primary),
                  title: const Text('Gruplarım'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const GroupListPage()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.create, color: AppColors.primary),
                  title: const Text('Grup Oluştur'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateGroupPage()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                  title: const Text('QR Kod ile Katıl'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const QRScannerPage()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.group_add, color: AppColors.primary),
                  title: const Text('Kod ile Katıl'),
                  onTap: () {
                    Navigator.pop(context);
                    // JoinGroupPage'e yönlendir
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => const JoinGroupPage()));
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Kod ile katılma özelliği yakında eklenecek')));
                  },
                ),
              ],
            ),
          ),
    );
  }
}
