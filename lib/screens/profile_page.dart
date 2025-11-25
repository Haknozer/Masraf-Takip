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

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  XFile? _pickedImage;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _darkModeEnabled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
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
      loading: () => BasePage(
        appBar: const ProfileAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => BasePage(
        appBar: const ProfileAppBar(),
        body: Center(child: Text("Hata: $e")),
      ),
      data: (user) {
        if (user == null) {
          return BasePage(
            appBar: const ProfileAppBar(),
            body: const Center(child: Text('Kullanıcı bulunamadı')),
          );
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
            CustomTextField(
              controller: _nameController,
              label: 'Kullanıcı Adı',
              hint: 'Kullanıcı adınızı girin',
              prefixIcon: Icons.person,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Lütfen kullanıcı adı girin';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.sectionMargin),
            CustomTextField(
              controller: _passwordController,
              label: 'Yeni Şifre',
              hint: 'Yeni şifrenizi girin (boş bırakabilirsiniz)',
              prefixIcon: Icons.lock,
              obscureText: true,
              validator: (value) {
                if (value != null && value.isNotEmpty && value.length < 6) {
                  return 'Şifre en az 6 karakter olmalıdır';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceCard() {
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
              subtitle: const Text('Yakında kullanılacak'),
              value: _darkModeEnabled,
              onChanged: (value) => setState(() => _darkModeEnabled = value),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    // Onay dialogu göster
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
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
      final password = _passwordController.text.trim();

      await ProfileController.updateProfile(
        ref,
        displayName: displayName,
        newPassword: password.isNotEmpty ? password : null,
        imageFile: _pickedImage,
      );

      if (mounted) {
        ErrorSnackBar.showSuccess(context, 'Profil başarıyla güncellendi!');
        // Şifre alanını temizle
        _passwordController.clear();
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

