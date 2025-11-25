import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class LoginAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LoginAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
      foregroundColor: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface,
      title: const Text('Giriş Yap'),
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
