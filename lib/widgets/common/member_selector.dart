import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';

/// Grup üyeleri seçim widget'ı
class MemberSelector extends ConsumerWidget {
  final List<String> selectedMemberIds;
  final Function(List<String> memberIds) onMembersChanged;
  final List<String> availableMemberIds;

  const MemberSelector({
    super.key,
    required this.selectedMemberIds,
    required this.onMembersChanged,
    required this.availableMemberIds,
  });

  Future<List<UserModel>> _getMembers(BuildContext context) async {
    final members = <UserModel>[];
    for (final memberId in availableMemberIds) {
      try {
        final userDoc = await FirebaseService.getDocumentSnapshot('users/$memberId');
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          members.add(UserModel.fromJson(data));
        }
      } catch (e) {
        // Hata durumunda devam et
      }
    }
    return members;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<UserModel>>(
      future: _getMembers(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Text('Üyeler yüklenemedi');
        }

        final members = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paylaşan Kişiler', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.textSpacing),
            Column(
              children: members.map((member) {
                final isSelected = selectedMemberIds.contains(member.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      final newSelection = List<String>.from(selectedMemberIds);
                      if (isSelected) {
                        newSelection.remove(member.id);
                      } else {
                        newSelection.add(member.id);
                      }
                      onMembersChanged(newSelection);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.greyLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.greyLight,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (isSelected)
                            Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                          else
                            Icon(Icons.circle_outlined, color: AppColors.textSecondary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              member.displayName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

