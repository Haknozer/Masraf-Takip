import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../widgets/common/image_picker_widget.dart';
import '../widgets/common/error_snackbar.dart';
import '../widgets/common/base_page.dart';
import '../widgets/forms/custom_text_field.dart';
import '../widgets/forms/custom_button.dart';
import '../widgets/app_bars/profile_app_bar.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_colors.dart';
import '../controllers/profile_controller.dart';
import '../models/user_model.dart';
import '../providers/theme_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  XFile? _pickedImage;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _initializeFields(String displayName) {
    if (!_isInitialized) {
      _nameController.text = displayName;
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userModelProvider);

    return userAsync.when(
      loading: () => BasePage(appBar: const ProfileAppBar(), body: const Center(child: CircularProgressIndicator())),
      error: (e, s) => BasePage(appBar: const ProfileAppBar(), body: Center(child: Text("Hata: $e"))),
      data: (user) {
        if (user == null) {
          return BasePage(appBar: const ProfileAppBar(), body: const Center(child: CircularProgressIndicator()));
        }

        _initializeFields(user.displayName);

        return BasePage(
          appBar: const ProfileAppBar(),
          body: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.sectionMargin),
                _buildProfileInfoCard(user),
                const SizedBox(height: AppSpacing.sectionMargin),
                _buildAccountSettingsCard(),
                const SizedBox(height: AppSpacing.sectionMargin),
                _buildAppearanceCard(),
                const SizedBox(height: AppSpacing.sectionMargin * 2),
                CustomButton(
                  text: 'Kaydet',
                  onPressed: _isLoading ? null : _onSave,
                  isLoading: _isLoading,
                  icon: Icons.save,
                ),
                const SizedBox(height: AppSpacing.sectionMargin),
                CustomButton(
                  text: 'Çıkış Yap',
                  onPressed: _isLoading ? null : _handleLogout,
                  isLoading: false,
                  icon: Icons.logout,
                  backgroundColor: AppColors.error,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileInfoCard(UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ImagePickerWidget(
              selectedImage: _pickedImage,
              currentImageUrl: user.photoUrl,
              onImageTap: _pickImage,
              onRemoveImage: () => setState(() => _pickedImage = null),
              size: 120,
            ),
            const SizedBox(height: AppSpacing.sectionMargin),
            const SizedBox(height: AppSpacing.sectionMargin),
            Column(
              children: [
                Text(user.displayName, style: AppTextStyles.h3),
                const SizedBox(height: 4),
                Text(user.email, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Hesap Ayarları', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.textSpacing),
            Text('Kullanıcı Adı', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5), width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _nameController.text,
                      style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionMargin),
            CustomButton(text: 'Şifreyi Değiştir', icon: Icons.lock_reset, onPressed: _showChangePasswordDialog),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceCard() {
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Görünüm', style: AppTextStyles.h3),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Karanlık Mod'),
              subtitle: const Text('Uygulamayı koyu tema ile kullan'),
              value: isDark,
              onChanged: (value) {
                ref.read(themeNotifierProvider.notifier).setDarkMode(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Şifre Değiştir'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomTextField(
                          controller: currentPasswordController,
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
                          controller: newPasswordController,
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
                          controller: confirmPasswordController,
                          label: 'Yeni Şifre (Tekrar)',
                          hint: 'Yeni şifreyi tekrar girin',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Yeni şifreyi tekrar girin';
                            }
                            if (value != newPasswordController.text) {
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
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('İptal'),
                ),
                TextButton(
                  onPressed:
                      isSubmitting
                          ? null
                          : () async {
                            if (!formKey.currentState!.validate()) return;

                            // Loading state'i güncelle
                            setState(() => isSubmitting = true);

                            try {
                              // Şifre değiştirme işlemini compute ile arka planda yap
                              await _performPasswordChange(
                                currentPassword: currentPasswordController.text.trim(),
                                newPassword: newPasswordController.text.trim(),
                              );

                              // Dialog'u güvenli şekilde kapat
                              if (Navigator.canPop(dialogContext)) {
                                Navigator.pop(dialogContext);
                              }

                              // Başarı mesajını ana context'te göster
                              if (mounted) {
                                ErrorSnackBar.showSuccess(context, 'Şifre başarıyla güncellendi');
                              }
                            } catch (e) {
                              // Detaylı hata yönetimi
                              String errorMessage = _getPasswordChangeErrorMessage(e);

                              // Hata durumunda state'i sıfırla
                              if (mounted) {
                                setState(() => isSubmitting = false);
                                ErrorSnackBar.show(context, errorMessage);
                              }
                            }
                          },
                  child:
                      isSubmitting
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                          )
                          : const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _performPasswordChange({required String currentPassword, required String newPassword}) async {
    try {
      await ProfileController.changePassword(ref, currentPassword: currentPassword, newPassword: newPassword);
    } catch (e) {
      // Hata yönetimi
      rethrow;
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

  Future<void> _handleLogout() async {
    // Onay dialogu göster
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Çıkış Yap'),
            content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Çıkış Yap'),
              ),
            ],
          ),
    );

    if (shouldLogout == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
    }
  }

  Future<void> _pickImage() async {
    final file = await ProfileController.pickProfileImage();
    if (file != null) {
      setState(() => _pickedImage = file);
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final displayName = _nameController.text.trim();

      await ProfileController.updateProfile(ref, displayName: displayName, imageFile: _pickedImage);

      if (mounted) {
        ErrorSnackBar.showSuccess(context, 'Profil başarıyla güncellendi!');
        // Seçili resmi temizle
        setState(() => _pickedImage = null);
        // UserModel'i yeniden yükle
        ref.invalidate(userModelProvider);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Profil güncellenemedi: ';
        if (e.toString().contains('weak-password')) {
          errorMessage = 'Şifre çok zayıf. Daha güçlü bir şifre seçin.';
        } else if (e.toString().contains('requires-recent-login')) {
          errorMessage = 'Şifre değiştirmek için tekrar giriş yapmanız gerekiyor.';
        } else {
          errorMessage = 'Profil güncellenemedi: ${e.toString()}';
        }
        ErrorSnackBar.show(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
