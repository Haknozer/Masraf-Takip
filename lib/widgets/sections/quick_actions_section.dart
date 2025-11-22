import 'package:flutter/material.dart';
import '../../constants/app_text_styles.dart';
import '../../models/group_model.dart';
import '../../widgets/dialogs/add_member_dialog.dart';
import '../../widgets/cards/action_card.dart';

class QuickActionsSection extends StatelessWidget {
  final GroupModel group;

  const QuickActionsSection({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
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
                  // Add expense
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ActionCard(
                icon: Icons.people_alt,
                title: 'Üye Ekle',
                onTap: () {
                  showDialog(context: context, builder: (context) => AddMemberDialog(group: group));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
