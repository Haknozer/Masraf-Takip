import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../selectors/member_selector_item.dart';

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
          children:
              members.map((member) {
                final isSelected = selectedMemberIds.contains(member.id);
                return MemberSelectorItem(
                  member: member,
                  isSelected: isSelected,
                  onTap: () {
                    final newSelection = List<String>.from(selectedMemberIds);
                    if (isSelected) {
                      newSelection.remove(member.id);
                    } else {
                      newSelection.add(member.id);
                    }
                    onMembersChanged(newSelection);
                  },
                );
              }).toList(),
        );
      },
    );
  }
}
