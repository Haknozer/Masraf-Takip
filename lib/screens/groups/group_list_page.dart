import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/group_provider.dart';
import '../../widgets/app_bars/group_list_app_bar.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/lists/groups_list.dart';
import '../../widgets/common/base_page.dart';
import '../../widgets/common/async_value_builder.dart';
import '../../models/group_model.dart';

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
    _tabController = TabController(length: 2, vsync: this);
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

    return BasePage(
      appBar: GroupListAppBar(
        searchQuery: _isSearching ? _searchQuery : null,
        searchController: _isSearching ? _searchController : null,
        onSearchChanged: _isSearching
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
          tabs: const [
            Tab(text: 'Aktif Gruplarım'),
            Tab(text: 'Geçmiş Gruplarım'),
          ],
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
              _buildGroupsTab(
                context,
                _filterGroups(_getActiveGroups(allGroups), _searchQuery),
                _searchQuery,
                'Aktif grup bulunamadı',
              ),
              // Geçmiş Gruplarım sekmesi
              _buildGroupsTab(
                context,
                _filterGroups(_getClosedGroups(allGroups), _searchQuery),
                _searchQuery,
                'Geçmiş grup bulunamadı',
              ),
            ],
          );
        },
        errorBuilder: (context, error, stack) => ErrorState(
          error: error.toString(),
          onRetry: () {
            // Retry logic
          },
        ),
      ),
    );
  }

  Widget _buildGroupsTab(
    BuildContext context,
    List<GroupModel> filteredGroups,
    String searchQuery,
    String emptyMessage,
  ) {
    if (filteredGroups.isEmpty) {
      if (searchQuery.isNotEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Arama sonucu bulunamadı',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '"$searchQuery" için sonuç bulunamadı',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          ),
        );
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _tabController.index == 0 ? Icons.group_outlined : Icons.history,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      );
    }
    return GroupsList(
      groups: filteredGroups,
      onRefresh: () async {
        // Refresh groups logic
      },
    );
  }
}
