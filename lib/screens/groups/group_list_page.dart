import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/group_provider.dart';
import '../../widgets/app_bars/group_list_app_bar.dart';
import '../../widgets/states/empty_groups_state.dart';
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

class _GroupListPageState extends ConsumerState<GroupListPage> {
  String _searchQuery = '';
  bool _isSearching = false;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      ),
      useScrollView: false,
      body: AsyncValueBuilder(
        value: groupsState,
        dataBuilder: (context, groups) {
          final filteredGroups = _filterGroups(groups, _searchQuery);
          
          if (filteredGroups.isEmpty) {
            if (_searchQuery.isNotEmpty) {
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
                        '"$_searchQuery" için sonuç bulunamadı',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const EmptyGroupsState();
          }
          return GroupsList(
            groups: filteredGroups,
            onRefresh: () async {
              // Refresh groups logic
            },
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
}
