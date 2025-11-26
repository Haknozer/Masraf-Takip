import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_spacing.dart';
import '../../providers/group_provider.dart';
import '../../models/group_model.dart';
import '../../widgets/app_bars/group_detail_app_bar.dart';
import '../../widgets/app_bars/profile_app_bar.dart';
import '../../widgets/common/async_value_builder.dart';
import '../../widgets/navigation/bottom_navigation_bar.dart';
import '../../widgets/dialogs/create_expense_dialog.dart';
import '../profile/profile_page.dart';
import '../../widgets/common/segment_control.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/tabs/group_members_tab.dart';
import '../../widgets/tabs/group_expenses_tab.dart';
import '../../widgets/tabs/group_settlement_tab.dart';

class GroupDetailPage extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends ConsumerState<GroupDetailPage> {
  int _currentIndex = 0; // Bottom navigation için
  int _selectedTab = 0; // Segment control için (0: Üyeler, 1: Masraflar, 2: Hesaplaşma)

  @override
  Widget build(BuildContext context) {
    debugPrint('GroupDetailPage build - GroupId: ${widget.groupId}, isEmpty: ${widget.groupId.isEmpty}');
    if (widget.groupId.isEmpty) {
      debugPrint('UYARI: GroupDetailPage\'e boş groupId geçirildi!');
    }

    final groupState = ref.watch(groupProvider(widget.groupId));

    return AsyncValueBuilder<GroupModel?>(
      value: groupState,
      dataBuilder: (context, group) {
        if (group == null) {
          return _buildScaffold(
            appBar: GroupDetailAppBar(groupId: widget.groupId),
            body: const Center(child: Text('Grup bulunamadı')),
          );
        }

        return _buildScaffold(
          appBar: GroupDetailAppBar(groupId: widget.groupId, group: group),
          body: _buildGroupDetail(group),
          group: group,
        );
      },
      loadingBuilder:
          (context) => _buildScaffold(
            appBar: GroupDetailAppBar(groupId: widget.groupId),
            body: const Center(child: CircularProgressIndicator()),
          ),
      errorBuilder:
          (context, error, stack) => _buildScaffold(
            appBar: GroupDetailAppBar(groupId: widget.groupId),
            body: Center(child: Text('Hata: $error')),
          ),
    );
  }

  Widget _buildScaffold({required PreferredSizeWidget appBar, required Widget body, GroupModel? group}) {
    final navItems = [
      const BottomNavItem(icon: Icons.home, label: 'Gruplar', index: 0),
      const BottomNavItem(icon: Icons.person_outline, label: 'Profil', index: 1),
    ];

    final pages = [
      _buildGroupDetailContent(body),
      const ProfilePage(showAppBar: false), // AppBar'ı burada göstermeyeceğiz
    ];

    // AppBar'ı dinamik olarak değiştir
    PreferredSizeWidget? currentAppBar;
    if (_currentIndex == 0) {
      // Grup detayı sayfasındayken
      currentAppBar = appBar;
    } else {
      // Profil sayfasındayken
      currentAppBar = const ProfileAppBar();
    }

    return Scaffold(
      appBar: currentAppBar,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 0) {
            // Gruplar'a tıklandığında ana sayfaya dön
            Navigator.popUntil(context, (route) => route.isFirst);
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        items: navItems,
        onFabTap:
            group != null && group.isActive
                ? () {
                  CreateExpenseDialog.show(context, group);
                }
                : null,
      ),
    );
  }

  Widget _buildGroupDetailContent(Widget body) {
    return body;
  }

  Widget _buildGroupDetail(GroupModel group) {
    return Column(
      children: [
        // Segment Control
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sectionPadding),
          child: SegmentControl(
            segments: const ['Üyeler', 'Masraflar', 'Hesaplaşma'],
            selectedIndex: _selectedTab,
            onSegmentChanged: (index) {
              setState(() {
                _selectedTab = index;
              });
            },
          ),
        ),
        // Tab Content
        Expanded(child: _buildTabContent(group)),
      ],
    );
  }

  Widget _buildTabContent(GroupModel group) {
    switch (_selectedTab) {
      case 0: // Üyeler
        final currentUser = ref.watch(currentUserProvider);
        final isMember = currentUser != null && group.isGroupMember(currentUser.uid);
        return GroupMembersTab(group: group, isMember: isMember);
      case 1: // Masraflar
        return GroupExpensesTab(group: group);
      case 2: // Hesaplaşma
        return GroupSettlementTab(group: group);
      default:
        return const SizedBox.shrink();
    }
  }
}
