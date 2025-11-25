import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';
import '../../services/deep_link_service.dart';
import '../../widgets/common/base_page.dart';
import '../../widgets/app_bars/join_group_app_bar.dart';
import '../../widgets/forms/custom_text_field.dart';
import '../../widgets/forms/custom_button.dart';
import '../../widgets/common/error_snackbar.dart';

class JoinGroupPage extends ConsumerStatefulWidget {
  const JoinGroupPage({super.key});

  @override
  ConsumerState<JoinGroupPage> createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends ConsumerState<JoinGroupPage> {
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
        // Deep link servisi zaten başarı mesajını gösteriyor, sadece sayfayı kapat
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return BasePage(
      appBar: const JoinGroupAppBar(),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.sectionMargin),
            // Başlık
            Text('Gruba Katıl', style: AppTextStyles.h1, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Davet kodunu girin',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sectionMargin * 2),

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
            CustomButton(text: 'Gruba Katıl', onPressed: _isLoading ? null : _joinGroup, isLoading: _isLoading),
          ],
        ),
      ),
    );
  }
}
