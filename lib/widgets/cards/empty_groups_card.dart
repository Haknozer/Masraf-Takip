import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../screens/groups/create_group_page.dart';

class EmptyGroupsCard extends StatelessWidget {
  const EmptyGroupsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.group_outlined, size: 60, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text('Henüz grup yok', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'İlk grubunuzu oluşturun veya bir gruba katılın',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateGroupPage()));
              },
              icon: const Icon(Icons.add),
              label: const Text('Grup Oluştur'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}
