import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class EditGroupAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EditGroupAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
      foregroundColor: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface,
      title: const Text('Grup Düzenle'),
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
