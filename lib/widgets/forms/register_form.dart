import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../utils/validators.dart';
import '../../utils/error_utils.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/forms/custom_text_field.dart';
import '../../widgets/forms/custom_button.dart';

class RegisterForm extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;

  const RegisterForm({super.key, required this.onSuccess});

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .signUp(_emailController.text.trim(), _passwordController.text, _nameController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt başarılı! Giriş yapabilirsiniz.'), backgroundColor: AppColors.success),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ErrorUtils.processError(e)), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
          // İsim Alanı
          CustomTextField(
            controller: _nameController,
            label: 'Ad Soyad',
            hint: 'Adınızı ve soyadınızı girin',
            prefixIcon: Icons.person,
            validator: Validators.validateName,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

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
          const SizedBox(height: 16),

          // Şifre Alanı
          CustomTextField(
            controller: _passwordController,
            label: 'Şifre',
            hint: 'En az 6 karakter',
            prefixIcon: Icons.lock,
            obscureText: !_isPasswordVisible,
            suffixIcon: IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                setState(() => _isPasswordVisible = !_isPasswordVisible);
              },
            ),
            validator: Validators.validatePassword,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // Şifre Tekrar Alanı
          CustomTextField(
            controller: _confirmPasswordController,
            label: 'Şifre Tekrar',
            hint: 'Şifrenizi tekrar girin',
            prefixIcon: Icons.lock_outline,
            obscureText: !_isConfirmPasswordVisible,
            suffixIcon: IconButton(
              icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
              },
            ),
            validator: (value) => Validators.validateConfirmPassword(value, _passwordController.text),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 32),

          // Kayıt Ol Butonu
          CustomButton(text: 'Kayıt Ol', onPressed: _isLoading ? null : _register, isLoading: _isLoading),
        ],
      ),
    );
  }
}
