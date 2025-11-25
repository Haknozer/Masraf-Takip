import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_text_styles.dart';
import '../../models/group_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dialogs/add_member_dialog.dart';
import '../../widgets/cards/action_card.dart';
import '../../widgets/dialogs/create_expense_dialog.dart';

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
                title: group.isActive ? 'Masraf Ekle' : 'Grup Kapalı',
                onTap:
                    group.isActive
                        ? () {
                          CreateExpenseDialog.show(context, group);
                        }
                        : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Grup kapalı. Yeni masraf eklenemez.',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                isDisabled: !group.isActive,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ActionCard(
                icon: Icons.people_alt,
                title: group.isActive ? 'Üye Ekle' : 'Grup Kapalı',
                onTap: group.isActive
                    ? () {
                        final currentUser = ref.read(currentUserProvider);
                        final isAdmin = group.isGroupAdmin(currentUser?.uid ?? '');

                        // Sadece admin görebilir
                        if (isAdmin) {
                          showDialog(
                            context: context,
                            builder: (context) => AddMemberDialog(group: group),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Sadece grup yöneticileri üye ekleyebilir',
                              ),
                            ),
                          );
                        }
                      }
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Grup kapalı. Yeni üye eklenemez.',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                isDisabled: !group.isActive,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
