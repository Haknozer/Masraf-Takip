import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';
import '../../models/group_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/copy_button.dart';
import '../../widgets/common/copyable_text_field.dart';
import '../../widgets/common/tab_button_widget.dart';

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
    final isAdmin = widget.group.isGroupAdmin(ref.read(currentUserProvider)?.uid ?? '');

    // Sadece admin görebilir
    if (!isAdmin) {
      return const SizedBox.shrink();
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
        return _buildQRCodeTab();
      case 1:
        return _buildLinkTab();
      case 2:
        return _buildCodeTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildQRCodeTab() {
    // QR kod verisi: Invite code (direkt kullan, şifreleme gerekmez)
    final qrData = widget.group.inviteCode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // QR Kod
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.greyLight),
          ),
          child: QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 200,
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
          ),
        ),
        const SizedBox(height: AppSpacing.sectionMargin),
        Text('QR kodu taratın', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'QR kod okutulduğunda kullanıcı direkt gruba katılacak',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLinkTab() {
    // Web URL formatı: https://masraftakipuygulamasi.web.app/join?code={inviteCode}
    // Bu link hem web'de hem uygulamada çalışır (App Links)
    final webLink = 'https://masraftakipuygulamasi.web.app/join?code=${widget.group.inviteCode}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.link, size: 64, color: AppColors.primary),
        const SizedBox(height: AppSpacing.sectionMargin),
        Text('Linki paylaşın', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Bu link hem web tarayıcısında hem uygulamada çalışır',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        // Web Link gösterimi
        CopyableTextField(text: webLink),
        const SizedBox(height: 8),
        CopyButton(text: webLink, buttonLabel: 'Linki Kopyala', successMessage: 'Link kopyalandı!'),
      ],
    );
  }

  Widget _buildCodeTab() {
    final inviteCode = widget.group.inviteCode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.code, size: 64, color: AppColors.primary),
        const SizedBox(height: AppSpacing.sectionMargin),
        Text('Davet Kodunu Paylaşın', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        // Kod gösterimi
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Text(inviteCode, style: AppTextStyles.h1.copyWith(color: AppColors.primary, letterSpacing: 4)),
        ),
        const SizedBox(height: 12),
        CopyButton(text: inviteCode, buttonLabel: 'Kodu Kopyala', successMessage: 'Kod kopyalandı!'),
        const SizedBox(height: 8),
        Text(
          'Kod ${_getDaysUntilExpiry()} gün geçerli',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  String _getDaysUntilExpiry() {
    final now = DateTime.now();
    final expiresAt = widget.group.inviteCodeExpiresAt;
    final difference = expiresAt.difference(now).inDays;
    return difference.toString();
  }
}
