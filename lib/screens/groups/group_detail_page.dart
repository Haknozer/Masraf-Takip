import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_spacing.dart';
import '../../providers/group_provider.dart';
import '../../models/group_model.dart';
import '../../widgets/app_bars/group_detail_app_bar.dart';
import '../../widgets/cards/group_header_card.dart';
import '../../widgets/sections/recent_expenses_section.dart';
import '../../widgets/sections/group_members_section.dart';
import '../../widgets/sections/settlement_section.dart';
import '../../widgets/common/async_value_builder.dart';
import '../../widgets/navigation/bottom_navigation_bar.dart';
import '../../widgets/dialogs/create_expense_dialog.dart';
import '../../screens/profile_page.dart';
import '../../widgets/common/segment_control.dart';
import '../../widgets/dialogs/add_member_dialog.dart';
import '../../providers/auth_provider.dart';

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
    print(
      'GroupDetailPage build - GroupId: ${widget.groupId}, isEmpty: ${widget.groupId.isEmpty}',
    );
    if (widget.groupId.isEmpty) {
      print('UYARI: GroupDetailPage\'e boş groupId geçirildi!');
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

  Widget _buildScaffold({
    required PreferredSizeWidget appBar,
    required Widget body,
    GroupModel? group,
  }) {
    final navItems = [
      const BottomNavItem(icon: Icons.home, label: 'Gruplar', index: 0),
      const BottomNavItem(
        icon: Icons.person_outline,
        label: 'Profil',
        index: 1,
      ),
    ];

    final pages = [
      _buildGroupDetailContent(body),
      const ProfilePage(),
    ];

    return Scaffold(
      appBar: appBar,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
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
        onFabTap: group != null && group.isActive
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
        Expanded(
          child: _buildTabContent(group),
        ),
      ],
    );
  }

  Widget _buildTabContent(GroupModel group) {
    switch (_selectedTab) {
      case 0: // Üyeler
        return _buildMembersTab(group);
      case 1: // Masraflar
        return _buildExpensesTab(group);
      case 2: // Hesaplaşma
        return _buildSettlementTab(group);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMembersTab(GroupModel group) {
    final currentUser = ref.watch(currentUserProvider);
    final isMember = currentUser != null && group.isGroupMember(currentUser.uid);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.sectionPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Header
          GroupHeaderCard(group: group),
          const SizedBox(height: AppSpacing.sectionMargin),
          // Group Members
          GroupMembersSection(group: group),
          // Üye Ekle Butonu (Tüm üyeler)
          if (isMember)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sectionMargin),
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AddMemberDialog(group: group),
                  );
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Üye Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpensesTab(GroupModel group) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.sectionPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Expenses
          RecentExpensesSection(groupId: group.id),
        ],
      ),
    );
  }

  Widget _buildSettlementTab(GroupModel group) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.sectionPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Settlement Section
          SettlementSection(group: group),
        ],
      ),
    );
  }
}
