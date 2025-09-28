import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../models/group_model.dart';
import '../groups/create_group_page.dart';
import '../groups/group_list_page.dart';
import '../groups/group_detail_page.dart';
import '../../widgets/cards/welcome_card.dart';
import '../../widgets/cards/group_card.dart';
import '../../widgets/cards/empty_groups_card.dart';
import '../../widgets/cards/error_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final groupsState = ref.watch(userGroupsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: const Text('Ana Sayfa'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hoş Geldiniz Bölümü - AppBar'ın hemen altında
            WelcomeCard(authState: authState),

            const SizedBox(height: 24),

            // Gruplarım Bölümü
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Gruplarım', style: AppTextStyles.h3),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const GroupListPage()));
                    },
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('Tümünü Gör'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Grup Listesi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: groupsState.when(
                data: (groups) {
                  if (groups.isEmpty) {
                    return const EmptyGroupsCard();
                  }
                  return _buildGroupsList(groups);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => ErrorCard(error: error.toString()),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showGroupOptions(context);
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  Widget _buildGroupsList(List<GroupModel> groups) {
    return Column(children: groups.take(3).map((group) => GroupCard(group: group)).toList());
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
                  leading: const Icon(Icons.group_add, color: AppColors.primary),
                  title: const Text('Gruba Katıl'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Gruba katılma özelliği yakında eklenecek')));
                  },
                ),
              ],
            ),
          ),
    );
  }
}
