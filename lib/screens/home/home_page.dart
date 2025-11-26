import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_spacing.dart';
import '../../widgets/sections/groups_section_header.dart';
import '../../widgets/sections/groups_list_section.dart';
import '../../widgets/sections/debt_summary_section.dart';
import '../../widgets/sections/friends_section.dart';
import '../../widgets/common/base_page.dart';
import '../../widgets/headers/home_header.dart';
import '../../widgets/dialogs/home/group_options_dialog.dart';
import '../../widgets/dialogs/home/create_group_dialog.dart';
import '../../widgets/dialogs/home/join_group_dialog.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  void _showGroupOptionsDialog(BuildContext context) {
    GroupOptionsDialog.show(
      context,
      onCreateGroup: () => CreateGroupDialog.show(context),
      onJoinWithCode: () => JoinGroupDialog.show(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      appBar: null,
      useScrollView: false,
      body: Column(
        children: [
          // Header: Masraf Takip + Yeni Grup Butonu
          HomeHeader(onNewGroupPressed: () => _showGroupOptionsDialog(context)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.sectionPadding),
              child: Column(
                children: [
                  // Borç Özeti Bölümü
                  const DebtSummarySection(),

                  const SizedBox(height: AppSpacing.sectionMargin),

                  // Gruplarım Bölümü
                  const GroupsSectionHeader(),
                  const SizedBox(height: AppSpacing.textSpacing),

                  // Grup Listesi
                  const GroupsListSection(),

                  const SizedBox(height: AppSpacing.sectionMargin),

                  // Arkadaşlarım Bölümü
                  const FriendsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
