import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_text_styles.dart';
import '../../../services/deep_link_service.dart';
import '../../common/error_snackbar.dart';
import '../../forms/custom_button.dart';
import '../../forms/custom_text_field.dart';

class JoinGroupDialog extends ConsumerStatefulWidget {
  const JoinGroupDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const JoinGroupDialog(),
    );
  }

  @override
  ConsumerState<JoinGroupDialog> createState() => _JoinGroupDialogState();
}

class _JoinGroupDialogState extends ConsumerState<JoinGroupDialog> {
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Davet kodunu girin',
                style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
              CustomButton(text: 'Gruba Katıl', onPressed: _isLoading ? null : _joinGroup, isLoading: _isLoading),
            ],
          ),
        ),
      ),
    );
  }
}

