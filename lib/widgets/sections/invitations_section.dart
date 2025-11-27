import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';
import '../../providers/invitation_provider.dart';
import '../cards/invitation_card.dart';

class InvitationsSection extends ConsumerWidget {
  const InvitationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitationsAsync = ref.watch(myInvitationsProvider);

    return invitationsAsync.when(
      data: (invitations) {
        if (invitations.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('Grup Davetleri', style: AppTextStyles.h3),
            ),
            const SizedBox(height: AppSpacing.textSpacing),
            ...invitations.map((invitation) => InvitationCard(invitation: invitation)),
            const SizedBox(height: AppSpacing.sectionMargin),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

