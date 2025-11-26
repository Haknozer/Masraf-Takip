import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';
import '../../models/group_model.dart';
import '../../widgets/common/tab_button_widget.dart';
import '../../widgets/forms/custom_button.dart';
import 'add_member/add_member_qr_tab.dart';
import 'add_member/add_member_link_tab.dart';
import 'add_member/add_member_code_tab.dart';

class AddMemberDialog extends ConsumerStatefulWidget {
  final GroupModel group;

  const AddMemberDialog({super.key, required this.group});

  @override
  ConsumerState<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends ConsumerState<AddMemberDialog> {
  int _selectedTab = 0; // 0: QR, 1: Link, 2: Kod

  @override
  Widget build(BuildContext context) {
    // Grup kapalıysa uyarı göster
    if (!widget.group.isActive) {
      return Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sectionPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, color: AppColors.warning, size: 48),
              const SizedBox(height: 16),
              Text('Grup Kapalı', style: AppTextStyles.h3),
              const SizedBox(height: 8),
              Text(
                'Grup kapalı olduğu için yeni üye eklenemez.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CustomButton(text: 'Tamam', onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sectionPadding),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Üye Ekle', style: AppTextStyles.h2),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionMargin),

              // Tab Bar
              _buildTabBar(),

              const SizedBox(height: AppSpacing.sectionMargin),

              // Tab Content
              _buildTabContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Row(
      children: [
        Expanded(
          child: TabButtonWidget(
            label: 'QR Kod',
            icon: Icons.qr_code,
            isSelected: _selectedTab == 0,
            onTap: () => setState(() => _selectedTab = 0),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TabButtonWidget(
            label: 'Link',
            icon: Icons.link,
            isSelected: _selectedTab == 1,
            onTap: () => setState(() => _selectedTab = 1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TabButtonWidget(
            label: 'Kod',
            icon: Icons.code,
            isSelected: _selectedTab == 2,
            onTap: () => setState(() => _selectedTab = 2),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return AddMemberQrTab(inviteCode: widget.group.inviteCode);
      case 1:
        return AddMemberLinkTab(inviteCode: widget.group.inviteCode);
      case 2:
        return AddMemberCodeTab(
          inviteCode: widget.group.inviteCode,
          inviteCodeExpiresAt: widget.group.inviteCodeExpiresAt,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
