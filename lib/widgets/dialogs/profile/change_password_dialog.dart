import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_spacing.dart';
import '../../../controllers/profile_controller.dart';
import '../../common/error_snackbar.dart';
import '../../forms/custom_text_field.dart';

class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  @override
  ConsumerState<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _performPasswordChange() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await ProfileController.changePassword(
        ref, 
        currentPassword: _currentPasswordController.text.trim(), 
        newPassword: _newPasswordController.text.trim()
      );

      if (mounted) {
        Navigator.pop(context);
        ErrorSnackBar.showSuccess(context, 'Şifre başarıyla güncellendi');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = _getPasswordChangeErrorMessage(e);
        setState(() => _isSubmitting = false);
        ErrorSnackBar.show(context, errorMessage);
      }
    }
  }

  String _getPasswordChangeErrorMessage(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'wrong-password':
          return 'Mevcut şifre yanlış. Lütfen kontrol edin.';
        case 'weak-password':
          return 'Yeni şifre çok zayıf. Daha güçlü bir şifre seçin.';
        case 'requires-recent-login':
          return 'Güvenlik için tekrar giriş yapmanız gerekiyor.';
        case 'user-mismatch':
          return 'Kullanıcı bilgileri uyuşmuyor.';
        case 'user-not-found':
          return 'Kullanıcı bulunamadı.';
        case 'invalid-email':
          return 'Geçersiz e-posta adresi.';
        case 'invalid-credential':
          return 'Geçersiz kimlik bilgileri.';
        case 'network-request-failed':
          return 'Ağ bağlantısı hatası. İnternet bağlantınızı kontrol edin.';
        default:
          return e.message ?? 'Bilinmeyen bir hata oluştu.';
      }
    } else if (e is Exception) {
      return e.toString();
    } else {
      return 'Şifre değiştirilemedi. Lütfen tekrar deneyin.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Şifre Değiştir'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: _currentPasswordController,
                  label: 'Mevcut Şifre',
                  hint: 'Mevcut şifrenizi girin',
                  prefixIcon: Icons.lock_open,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Mevcut şifrenizi girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sectionMargin),
                CustomTextField(
                  controller: _newPasswordController,
                  label: 'Yeni Şifre',
                  hint: 'Yeni şifrenizi girin',
                  prefixIcon: Icons.lock,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Yeni şifrenizi girin';
                    }
                    if (value.length < 6) {
                      return 'Şifre en az 6 karakter olmalıdır';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sectionMargin),
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Yeni Şifre (Tekrar)',
                  hint: 'Yeni şifreyi tekrar girin',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Yeni şifreyi tekrar girin';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Şifreler eşleşmiyor';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        TextButton(
          onPressed: _isSubmitting ? null : _performPasswordChange,
          child:
              _isSubmitting
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                  )
                  : const Text('Kaydet'),
        ),
      ],
    );
  }
}

