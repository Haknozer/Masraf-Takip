import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../widgets/app_bars/register_app_bar.dart';
import '../../widgets/sections/register_header.dart';
import '../../widgets/forms/register_form.dart';
import '../../widgets/sections/register_footer.dart';

class RegisterPage extends ConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const RegisterAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.sectionPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const RegisterHeader(),
              RegisterForm(
                onSuccess: () {
                  Navigator.pop(context);
                },
              ),
              const RegisterFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
