import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class GroupListAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? searchQuery;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onSearchCancel;

  const GroupListAppBar({
    super.key,
    this.searchQuery,
    this.searchController,
    this.onSearchChanged,
    this.onSearchPressed,
    this.onSearchCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foregroundColor = theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface;
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
      foregroundColor: foregroundColor,
      title: searchController != null && onSearchChanged != null
          ? TextField(
              controller: searchController,
              autofocus: true,
              style: TextStyle(color: foregroundColor),
              decoration: InputDecoration(
                hintText: 'Grup ara...',
                hintStyle: TextStyle(color: foregroundColor.withOpacity(0.7)),
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear, color: foregroundColor),
                  onPressed: () {
                    searchController?.clear();
                    onSearchChanged?.call('');
                    onSearchCancel?.call();
                  },
                ),
              ),
              onChanged: onSearchChanged,
            )
          : const Text('Gruplarım'),
      elevation: 0,
      actions: [
        if (searchQuery == null || onSearchChanged == null)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: onSearchPressed,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
