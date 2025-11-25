import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../screens/home/home_page.dart';
import '../../screens/profile_page.dart';
import '../../providers/group_provider.dart';
import '../../widgets/dialogs/select_group_dialog.dart';
import '../../widgets/dialogs/create_expense_dialog.dart';
import 'bottom_navigation_bar.dart';

/// Ana navigasyon wrapper - Bottom navigation bar ile
class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(), // Ana Sayfa/Gruplar (index 0) - Görselde "Gruplar" butonu Ana Sayfa'yı gösteriyor
    const ProfilePage(), // Profil (index 1)
  ];

  @override
  Widget build(BuildContext context) {
    final navItems = [
      const BottomNavItem(icon: Icons.home, label: 'Gruplar', index: 0),
      const BottomNavItem(
        icon: Icons.person_outline,
        label: 'Profil',
        index: 1,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: navItems,
        onFabTap: () => _showExpenseDialog(context),
      ),
    );
  }

  void _showExpenseDialog(BuildContext context) async {
    // Kullanıcının gruplarını al
    final groupsState = ref.read(userGroupsProvider);
    final groups = groupsState.valueOrNull ?? [];

    if (groups.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Önce bir grup oluşturmanız veya bir gruba katılmanız gerekiyor.',
            ),
          ),
        );
      }
      return;
    }

    // Grup seçim dialogu göster
    final selectedGroup = await showDialog(
      context: context,
      builder: (context) => SelectGroupDialog(groups: groups),
    );

    if (selectedGroup != null && mounted) {
      // Masraf ekleme dialog'unu göster
      await CreateExpenseDialog.show(context, selectedGroup);
    }
  }
}
