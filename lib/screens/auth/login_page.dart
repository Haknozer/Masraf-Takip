import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../widgets/app_bars/login_app_bar.dart';
import '../../widgets/sections/login_header.dart';
import '../../widgets/forms/login_form.dart';
import '../../widgets/sections/login_footer.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const LoginAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.sectionPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LoginHeader(),
              LoginForm(
                onSuccess: () {
                  // Navigation will be handled by the auth state listener
                },
              ),
              const LoginFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
