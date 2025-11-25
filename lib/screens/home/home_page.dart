import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/sections/groups_section_header.dart';
import '../../widgets/sections/groups_list_section.dart';
import '../../widgets/sections/debt_summary_section.dart';
import '../../widgets/common/base_page.dart';
import '../../widgets/forms/custom_button.dart';
import '../../widgets/forms/create_group_form.dart';
import '../../providers/group_provider.dart';
import '../../screens/groups/qr_scanner_page.dart';
import '../../services/deep_link_service.dart';
import '../../widgets/forms/custom_text_field.dart';
import '../../widgets/common/error_snackbar.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final code = _codeController.text.trim().toUpperCase();
      
      // Girilen kodu URL formatına çevir ve deep link servisiyle işle
      final joinUrl = Uri.parse('https://masraftakipuygulamasi.web.app/join?code=$code');
      await DeepLinkService.handleDeepLink(joinUrl, context, ref);

      if (mounted) {
        // Deep link servisi zaten başarı mesajını gösteriyor, sadece dialog'u kapat
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context); // Dialog'u kapat
            _codeController.clear();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Gruba katılma hatası: ';
        if (e.toString().contains('NotFoundException')) {
          errorMessage = 'Geçersiz veya süresi dolmuş davet kodu.';
        } else if (e.toString().contains('InvalidOperationException')) {
          errorMessage = 'Bu grubun zaten üyesisiniz.';
        } else {
          errorMessage = 'Gruba katılma hatası: ${e.toString()}';
        }

        ErrorSnackBar.show(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showJoinGroupDialog(BuildContext context) {
    _codeController.clear();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(AppSpacing.sectionPadding),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Kod ile Katıl', style: AppTextStyles.h3),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Davet kodunu girin',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionMargin),
                // Kod girişi
                CustomTextField(
                  controller: _codeController,
                  label: 'Davet Kodu',
                  hint: 'ABC12',
                  prefixIcon: Icons.code,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen davet kodunu girin';
                    }
                    final trimmedValue = value.trim();
                    if (trimmedValue.length < 4 || trimmedValue.length > 5) {
                      return 'Davet kodu 4-5 karakter olmalıdır';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sectionMargin),
                // Katıl butonu
                CustomButton(
                  text: 'Gruba Katıl',
                  onPressed: _isLoading ? null : _joinGroup,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGroupOptionsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Grup İşlemleri',
                style: AppTextStyles.h2,
              ),
              const SizedBox(height: 24),
              // Yeni Grup Oluştur
              ListTile(
                leading: const Icon(Icons.create, color: AppColors.primary),
                title: const Text('Yeni Grup Oluştur'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateGroupDialog(context, ref);
                },
              ),
              // QR Kod ile Katıl
              ListTile(
                leading: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                title: const Text('QR Kod ile Katıl'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const QRScannerPage()),
                  );
                },
              ),
              // Kod ile Katıl
              ListTile(
                leading: const Icon(Icons.group_add, color: AppColors.primary),
                title: const Text('Kod ile Katıl'),
                onTap: () {
                  Navigator.pop(context);
                  _showJoinGroupDialog(context);
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          padding: const EdgeInsets.all(AppSpacing.sectionPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Yeni Grup Oluştur', style: AppTextStyles.h3),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionMargin),
              Flexible(
                child: SingleChildScrollView(
                  child: CreateGroupForm(
                    onSuccess: () {
                      Navigator.pop(context);
                      // Grupları yenile
                      ref.invalidate(userGroupsProvider);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sectionPadding,
              AppSpacing.sectionPadding + 8,
              AppSpacing.sectionPadding,
              AppSpacing.sectionPadding,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primaryLight,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Masraf Takip',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CustomButton(
                    text: 'Yeni Grup',
                    onPressed: () => _showGroupOptionsDialog(context, ref),
                    icon: Icons.add,
                    height: 40,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  ),
                ],
              ),
            ),
          ),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
