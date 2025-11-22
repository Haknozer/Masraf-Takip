import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/app_bars/login_app_bar.dart';
import '../../widgets/sections/login_header.dart';
import '../../widgets/forms/login_form.dart';
import '../../widgets/sections/login_footer.dart';
import '../../widgets/common/base_page.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BasePage(
      appBar: const LoginAppBar(),
      body: Column(
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
    );
  }
}
