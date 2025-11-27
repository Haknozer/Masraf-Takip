import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_spacing.dart';
import '../../providers/debt_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/invitation_provider.dart';
import '../../widgets/sections/groups_section_header.dart';
import '../../widgets/sections/groups_list_section.dart';
import '../../widgets/sections/debt_summary_section.dart';
import '../../widgets/sections/friends_section.dart';
import '../../widgets/sections/invitations_section.dart';
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

  Future<void> _onRefresh() async {
    // Tüm ana veri providerlarını yenile
    ref.invalidate(userDebtSummaryProvider);
    ref.invalidate(groupNotifierProvider);
    ref.invalidate(userFriendsProvider);
    ref.invalidate(myInvitationsProvider);
    // Kısa bir gecikme ekle ki kullanıcı yenilendiğini hissetsin
    await Future.delayed(const Duration(milliseconds: 500));
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
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.sectionPadding),
                child: Column(
                  children: [
                    // Davetler Bölümü
                    const InvitationsSection(),

                    // Borç Özeti Bölümü
                    const DebtSummarySection(),

                    const SizedBox(height: AppSpacing.sectionMargin),

                    // Gruplarım Bölümü
                    const GroupsSectionHeader(),
                    const SizedBox(height: AppSpacing.textSpacing),

                    // Grup Listesi
                    const GroupsListSection(),

                    // Arkadaşlarım Bölümü
                    const FriendsSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
