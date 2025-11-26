import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/common/base_page.dart';
import '../../widgets/forms/custom_button.dart';
import '../../widgets/app_bars/profile_app_bar.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_colors.dart';
import '../../controllers/profile_controller.dart';
import '../../widgets/cards/profile/profile_info_card.dart';
import '../../widgets/cards/profile/account_settings_card.dart';
import '../../widgets/cards/profile/appearance_card.dart';
import '../../widgets/dialogs/profile/change_password_dialog.dart';
import '../../widgets/dialogs/profile/logout_confirmation_dialog.dart';

class ProfilePage extends ConsumerStatefulWidget {
  final bool showAppBar;

  const ProfilePage({super.key, this.showAppBar = true});

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

  Future<void> _pickImage() async {
    final file = await ProfileController.pickProfileImage();
    if (file != null) {
      setState(() => _pickedImage = file);
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await LogoutConfirmationDialog.show(context);

    if (shouldLogout == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
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

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userModelProvider);

    return userAsync.when(
      loading:
          () => BasePage(
            appBar: widget.showAppBar ? const ProfileAppBar() : null,
            body: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (e, s) =>
              BasePage(appBar: widget.showAppBar ? const ProfileAppBar() : null, body: Center(child: Text("Hata: $e"))),
      data: (user) {
        if (user == null) {
          return BasePage(
            appBar: widget.showAppBar ? const ProfileAppBar() : null,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        _initializeFields(user.displayName);

        return BasePage(
          appBar: widget.showAppBar ? const ProfileAppBar() : null,
          body: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.sectionMargin),
                ProfileInfoCard(
                  user: user,
                  pickedImage: _pickedImage,
                  onImageTap: _pickImage,
                  onRemoveImage: () => setState(() => _pickedImage = null),
                ),
                const SizedBox(height: AppSpacing.sectionMargin),
                AccountSettingsCard(
                  nameController: _nameController,
                  onChangePassword: () => ChangePasswordDialog.show(context),
                ),
                const SizedBox(height: AppSpacing.sectionMargin),
                const AppearanceCard(),
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
}
