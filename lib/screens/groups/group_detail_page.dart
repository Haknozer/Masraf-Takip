import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../providers/group_provider.dart';
import '../../models/group_model.dart';

class GroupDetailPage extends ConsumerWidget {
  final String groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupState = ref.watch(groupProvider(groupId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: const Text('Grup Detayı'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Group settings
            },
          ),
        ],
      ),
      body: groupState.when(
        data: (group) {
          if (group == null) {
            return const Center(child: Text('Grup bulunamadı'));
          }
          return _buildGroupDetail(group);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Hata: $error')),
      ),
    );
  }

  Widget _buildGroupDetail(GroupModel group) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.group, color: AppColors.primary, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(group.name, style: AppTextStyles.h2),
                            if (group.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                group.description,
                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoItem(Icons.people, '${group.memberIds.length} Üye'),
                      const SizedBox(width: 24),
                      _buildInfoItem(Icons.calendar_today, _formatDate(group.createdAt)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick Actions
          Text('Hızlı İşlemler', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.add,
                  title: 'Masraf Ekle',
                  onTap: () {
                    // Add expense
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.people_alt,
                  title: 'Üye Ekle',
                  onTap: () {
                    // Add member
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Expenses
          Text('Son Masraflar', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          _buildExpenseList(),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildActionCard({required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 32),
              const SizedBox(height: 8),
              Text(title, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.receipt, color: AppColors.primary),
              title: const Text('Kahve'),
              subtitle: const Text('Starbucks'),
              trailing: Text('₺25.50', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success)),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.restaurant, color: AppColors.primary),
              title: const Text('Yemek'),
              subtitle: const Text('Pizza Palace'),
              trailing: Text('₺120.00', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success)),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.local_gas_station, color: AppColors.primary),
              title: const Text('Benzin'),
              subtitle: const Text('Shell'),
              trailing: Text('₺300.00', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
