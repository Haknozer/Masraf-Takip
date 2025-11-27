import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_colors.dart';
import '../../models/group_model.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';

class BlockedGroupsSection extends ConsumerWidget {
  const BlockedGroupsSection({super.key});

  Future<void> _unblockGroup(BuildContext context, WidgetRef ref, GroupModel group) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final userDocSnapshot =
          await FirebaseService.firestore.collection('users').where('id', isEqualTo: user.uid).limit(1).get();

      if (userDocSnapshot.docs.isEmpty) return;

      final userDocId = userDocSnapshot.docs.first.id;

      await FirebaseService.updateDocument(
        path: 'users/$userDocId',
        data: {
          'blockedGroupIds': FieldValue.arrayRemove([group.id]),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${group.name}" engellemesi kaldırıldı.')));

      ref.invalidate(blockedGroupsProvider);
      ref.invalidate(userModelProvider);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Engelleme kaldırılamadı: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedGroupsAsync = ref.watch(blockedGroupsProvider);

    return blockedGroupsAsync.when(
      data: (blockedGroups) {
        if (blockedGroups.isEmpty) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sectionMargin),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.block, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text('Engellediğim Gruplar', style: AppTextStyles.h4),
                  ],
                ),
                const SizedBox(height: AppSpacing.textSpacing),
                ...blockedGroups.map((group) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(group.name, style: AppTextStyles.bodyMedium),
                    subtitle: Text(
                      group.description.isNotEmpty ? group.description : 'Açıklama yok',
                      style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    trailing: TextButton(
                      onPressed: () => _unblockGroup(context, ref, group),
                      child: const Text('Engeli Kaldır'),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
