import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';
import '../../utils/validators.dart';
import '../../utils/error_utils.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/forms/custom_text_field.dart';
import '../../widgets/forms/custom_button.dart';
import '../../widgets/common/error_snackbar.dart';

class LoginForm extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;

  const LoginForm({super.key, required this.onSuccess});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authNotifierProvider.notifier).signIn(_emailController.text.trim(), _passwordController.text);

      if (mounted) {
        ErrorSnackBar.showSuccess(context, 'Giriş başarılı!');
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, ErrorUtils.processError(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      ErrorSnackBar.showWarning(context, 'Lütfen email adresinizi girin');
      return;
    }

    try {
      await ref.read(authNotifierProvider.notifier).resetPassword(_emailController.text.trim());

      if (mounted) {
        ErrorSnackBar.showSuccess(context, 'Şifre sıfırlama linki email adresinize gönderildi');
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, ErrorUtils.processError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Alanı
          CustomTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'email@example.com',
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.textSpacing * 2),

          // Şifre Alanı
          CustomTextField(
            controller: _passwordController,
            label: 'Şifre',
            hint: 'Şifrenizi girin',
            prefixIcon: Icons.lock,
            obscureText: !_isPasswordVisible,
            suffixIcon: IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                setState(() => _isPasswordVisible = !_isPasswordVisible);
              },
            ),
            validator: Validators.validatePassword,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.textSpacing),

          // Şifremi Unuttum
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _resetPassword,
              child: Text('Şifremi Unuttum', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
            ),
          ),
          const SizedBox(height: AppSpacing.sectionMargin),

          // Giriş Yap Butonu
          CustomButton(text: 'Giriş Yap', onPressed: _isLoading ? null : _login, isLoading: _isLoading),
        ],
      ),
    );
  }
}
