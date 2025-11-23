import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/cards/welcome_card.dart';
import '../../widgets/app_bars/home_app_bar.dart';
import '../../widgets/sections/groups_section_header.dart';
import '../../widgets/sections/groups_list_section.dart';
import '../../widgets/sections/debt_summary_section.dart';
import '../../widgets/buttons/group_options_fab.dart';
import '../../widgets/common/base_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return BasePage(
      appBar: const HomeAppBar(),
      useScrollView: false,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hoş Geldiniz Bölümü - AppBar'ın hemen altında
            WelcomeCard(authState: authState),

            const SizedBox(height: AppSpacing.sectionMargin),

            // Borç Özeti Bölümü
            const DebtSummarySection(),

            const SizedBox(height: AppSpacing.sectionMargin),

            // Gruplarım Bölümü
            const GroupsSectionHeader(),
            const SizedBox(height: AppSpacing.textSpacing),

            // Grup Listesi
            const GroupsListSection(),
          ],
        ),
      ),
      floatingActionButton: const GroupOptionsFAB(),
    );
  }
}
