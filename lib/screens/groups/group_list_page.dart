import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/app_bars/group_list_app_bar.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/common/base_page.dart';
import '../../widgets/common/async_value_builder.dart';
import '../../models/group_model.dart';
import '../../widgets/views/groups_tab_view.dart';

class GroupListPage extends ConsumerStatefulWidget {
  const GroupListPage({super.key});

  @override
  ConsumerState<GroupListPage> createState() => _GroupListPageState();
}

class _GroupListPageState extends ConsumerState<GroupListPage> with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  bool _isSearching = false;
  late final TextEditingController _searchController;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<GroupModel> _filterGroups(List<GroupModel> groups, String query) {
    if (query.isEmpty) {
      return groups;
    }
    final lowerQuery = query.toLowerCase();
    return groups.where((group) {
      return group.name.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  List<GroupModel> _getActiveGroups(List<GroupModel> groups) {
    return groups.where((group) => group.isActive).toList();
  }

  List<GroupModel> _getClosedGroups(List<GroupModel> groups) {
    return groups.where((group) => !group.isActive).toList();
  }

  @override
  Widget build(BuildContext context) {
    final groupsState = ref.watch(userGroupsProvider);
    final blockedGroupsState = ref.watch(blockedGroupsProvider);

    return BasePage(
      appBar: GroupListAppBar(
        searchQuery: _isSearching ? _searchQuery : null,
        searchController: _isSearching ? _searchController : null,
        onSearchChanged:
            _isSearching
                ? (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                }
                : null,
        onSearchPressed: () {
          setState(() {
            _isSearching = true;
          });
        },
        onSearchCancel: () {
          setState(() {
            _isSearching = false;
            _searchQuery = '';
            _searchController.clear();
          });
        },
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Aktif Gruplarım'), Tab(text: 'Geçmiş Gruplarım'), Tab(text: 'Engellediğim Gruplar')],
        ),
      ),
      useScrollView: false,
      body: AsyncValueBuilder(
        value: groupsState,
        dataBuilder: (context, allGroups) {
          return TabBarView(
            controller: _tabController,
            children: [
              // Aktif Gruplarım sekmesi
              GroupsTabView(
                groups: _filterGroups(_getActiveGroups(allGroups), _searchQuery),
                searchQuery: _searchQuery,
                emptyMessage: 'Aktif grup bulunamadı',
                isHistoryTab: false,
                onRefresh: () async {
                  // Refresh groups logic
                },
              ),
              // Geçmiş Gruplarım sekmesi
              GroupsTabView(
                groups: _filterGroups(_getClosedGroups(allGroups), _searchQuery),
                searchQuery: _searchQuery,
                emptyMessage: 'Geçmiş grup bulunamadı',
                isHistoryTab: true,
                onRefresh: () async {
                  // Refresh groups logic
                },
              ),
              // Engellediğim Gruplar sekmesi
              blockedGroupsState.when(
                data:
                    (blockedGroups) => GroupsTabView(
                      groups: _filterGroups(blockedGroups, _searchQuery),
                      searchQuery: _searchQuery,
                      emptyMessage: 'Engellediğiniz grup bulunamadı',
                      isHistoryTab: true,
                      onRefresh: () async {
                        // Refresh logic
                      },
                      onUnblock: _unblockGroup,
                    ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, stack) => ErrorState(
                      error: error.toString(),
                      onRetry: () {
                        // Retry engellenenler
                      },
                    ),
              ),
            ],
          );
        },
        errorBuilder:
            (context, error, stack) => ErrorState(
              error: error.toString(),
              onRetry: () {
                // Retry logic
              },
            ),
      ),
    );
  }

  Future<void> _unblockGroup(GroupModel group) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final userDocSnapshot =
          await FirebaseService.firestore.collection('users').where('id', isEqualTo: user.uid).limit(1).get();

      if (userDocSnapshot.docs.isEmpty) return;

      final userDocId = userDocSnapshot.docs.first.id;

      await FirebaseService.updateDocument(
        path: 'users/$userDocId',
        data: {
          'blockedGroupIds': FieldValue.arrayRemove([group.id]),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${group.name}" engellemesi kaldırıldı.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Engelleme kaldırılamadı: $e')));
    }
  }
}
