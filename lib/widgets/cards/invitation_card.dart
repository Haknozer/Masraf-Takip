import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/invitation_model.dart';
import '../../controllers/invitation_controller.dart';
import '../common/error_snackbar.dart';

class InvitationCard extends ConsumerStatefulWidget {
  final InvitationModel invitation;

  const InvitationCard({super.key, required this.invitation});

  @override
  ConsumerState<InvitationCard> createState() => _InvitationCardState();
}

class _InvitationCardState extends ConsumerState<InvitationCard> {
  bool _isProcessing = false;

  Future<void> _handleAction(Future<void> Function() action, String successMessage) async {
    setState(() => _isProcessing = true);
    try {
      await action();
      if (mounted) {
        ErrorSnackBar.showSuccess(context, successMessage);
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mail_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.invitation.inviterName} sizi "${widget.invitation.groupName}" grubuna davet etti.',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Engelle
                TextButton(
                  onPressed: _isProcessing
                      ? null
                      : () => _handleAction(
                            () => ref.read(invitationControllerProvider).blockGroup(widget.invitation),
                            'Grup engellendi',
                          ),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Engelle'),
                ),
                const SizedBox(width: 8),
                // Reddet
                OutlinedButton(
                  onPressed: _isProcessing
                      ? null
                      : () => _handleAction(
                            () => ref.read(invitationControllerProvider).rejectInvitation(widget.invitation.id),
                            'Davet reddedildi',
                          ),
                  child: const Text('Reddet'),
                ),
                const SizedBox(width: 8),
                // Kabul Et
                ElevatedButton(
                  onPressed: _isProcessing
                      ? null
                      : () => _handleAction(
                            () => ref.read(invitationControllerProvider).acceptInvitation(widget.invitation),
                            'Gruba katıldınız',
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Kabul Et'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

