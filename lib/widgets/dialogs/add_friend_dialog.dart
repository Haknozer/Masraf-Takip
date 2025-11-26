import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../providers/friend_provider.dart';
import '../common/error_snackbar.dart';
import '../forms/custom_text_field.dart';

/// Arkadaş ekleme dialogu
class AddFriendDialog extends ConsumerStatefulWidget {
  const AddFriendDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(context: context, builder: (context) => const AddFriendDialog());
  }

  @override
  ConsumerState<AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends ConsumerState<AddFriendDialog> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    final input = _emailController.text.trim();

    if (input.isEmpty) {
      ErrorSnackBar.show(context, 'Lütfen bir email adresi veya kullanıcı adı girin');
      return;
    }

    // Email veya kullanıcı adı formatı kontrolü
    final isEmail = input.contains('@');
    if (isEmail) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(input)) {
        ErrorSnackBar.show(context, 'Geçerli bir email adresi girin');
        return;
      }
    } else {
      // Kullanıcı adı formatı kontrolü
      if (input.length < 3) {
        ErrorSnackBar.show(context, 'Kullanıcı adı en az 3 karakter olmalı');
        return;
      }
      final usernameRegex = RegExp(r'^[a-zA-Z0-9._]+$');
      if (!usernameRegex.hasMatch(input)) {
        ErrorSnackBar.show(context, 'Geçersiz kullanıcı adı formatı');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(friendNotifierProvider.notifier).sendFriendRequest(input);
      if (mounted) {
        ErrorSnackBar.showSuccess(context, 'Arkadaşlık isteği gönderildi');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.person_add, color: colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Arkadaş Ekle'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Arkadaş eklemek istediğiniz kişinin email adresi veya kullanıcı adını girin',
            style: AppTextStyles.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _emailController,
            label: 'Email veya Kullanıcı Adı',
            hint: 'ornek@email.com veya kullanici_adi',
            prefixIcon: Icons.person_search,
            keyboardType: TextInputType.text,
            readOnly: _isLoading,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('İptal')),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendRequest,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                  : const Text('Gönder'),
        ),
      ],
    );
  }
}
