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
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      title: searchController != null && onSearchChanged != null
          ? TextField(
              controller: searchController,
              autofocus: true,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                hintText: 'Grup ara...',
                hintStyle: TextStyle(color: AppColors.white.withOpacity(0.7)),
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.white),
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
