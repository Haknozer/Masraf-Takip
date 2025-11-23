import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_text_styles.dart';
import '../../models/group_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dialogs/add_member_dialog.dart';
import '../../widgets/cards/action_card.dart';
import '../../screens/expenses/create_expense_page.dart';

class QuickActionsSection extends ConsumerWidget {
  final GroupModel group;

  const QuickActionsSection({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hızlı İşlemler', style: AppTextStyles.h3),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ActionCard(
                icon: Icons.add,
                title: 'Masraf Ekle',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => CreateExpensePage(group: group)));
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ActionCard(
                icon: Icons.people_alt,
                title: 'Üye Ekle',
                onTap: () {
                  final currentUser = ref.read(currentUserProvider);
                  final isAdmin = group.isGroupAdmin(currentUser?.uid ?? '');

                  // Sadece admin görebilir
                  if (isAdmin) {
                    showDialog(context: context, builder: (context) => AddMemberDialog(group: group));
                  } else {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Sadece grup yöneticileri üye ekleyebilir')));
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
