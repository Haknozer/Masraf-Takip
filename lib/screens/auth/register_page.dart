import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/app_bars/register_app_bar.dart';
import '../../widgets/sections/register_header.dart';
import '../../widgets/forms/register_form.dart';
import '../../widgets/sections/register_footer.dart';
import '../../widgets/common/base_page.dart';

class RegisterPage extends ConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BasePage(
      appBar: const RegisterAppBar(),
      body: Column(
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
    );
  }
}
