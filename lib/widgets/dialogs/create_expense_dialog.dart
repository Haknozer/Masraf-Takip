import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';
import '../../models/group_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/common/category_selector.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/common/manual_distribution_input.dart';
import '../../widgets/common/member_selector.dart';
import '../../widgets/common/payment_type_selector.dart';
import '../../widgets/forms/custom_button.dart';
import '../../widgets/forms/custom_text_field.dart';

/// Masraf ekleme dialog'u
class CreateExpenseDialog extends ConsumerStatefulWidget {
  final GroupModel group;

  const CreateExpenseDialog({super.key, required this.group});

  static Future<void> show(BuildContext context, GroupModel group) async {
    // Grup kapalıysa dialog açma, uyarı göster
    if (!group.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Grup kapalı. Yeni masraf eklenemez.'),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateExpenseDialog(group: group),
    );
  }

  @override
  ConsumerState<CreateExpenseDialog> createState() => _CreateExpenseDialogState();
}

class _CreateExpenseDialogState extends ConsumerState<CreateExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  XFile? _receiptImage;

  String? _selectedCategoryId;
  DistributionType? _distributionType;
  List<String> _selectedMemberIds = [];
  Map<String, double> _manualAmounts = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Varsayılan olarak hiçbir üye seçili değil
    _selectedMemberIds = [];
    // Varsayılan olarak eşit dağılım
    _distributionType = DistributionType.equal;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _receiptImage = null;
    super.dispose();
  }

  Future<void> _createExpense() async {
    // Grup kapalı kontrolü
    if (!widget.group.isActive) {
      ErrorSnackBar.showWarning(context, 'Grup kapalı. Yeni masraf eklenemez.');
      Navigator.pop(context);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    // Validasyonlar
    if (_selectedCategoryId == null) {
      ErrorSnackBar.showWarning(context, 'Lütfen bir kategori seçin (zorunlu)');
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    if (amount <= 0) {
      ErrorSnackBar.showWarning(context, 'Tutar 0\'dan büyük olmalıdır');
      return;
    }

    if (_selectedMemberIds.isEmpty) {
      ErrorSnackBar.showWarning(context, 'Lütfen en az bir kişi seçin');
      return;
    }

    if (_distributionType == null) {
      ErrorSnackBar.showWarning(context, 'Lütfen dağılım tipini seçin');
      return;
    }

    if (_distributionType == DistributionType.manual) {
      // Manuel dağılım: Toplam kontrolü
      final total = _manualAmounts.values.fold(0.0, (sum, amt) => sum + amt);
      if ((total - amount).abs() > 0.01) {
        ErrorSnackBar.showWarning(context, 'Manuel dağılım toplamı tutara eşit olmalıdır');
        return;
      }
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ErrorSnackBar.show(context, 'Giriş yapmanız gerekiyor');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_receiptImage != null) {
        final fileName = '${widget.group.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageUrl = await FirebaseService.uploadFile(path: 'expense_receipts/$fileName', file: _receiptImage!);
      }

      // Manuel dağılım varsa manualAmounts'ı gönder
      Map<String, double>? manualAmounts;
      if (_distributionType == DistributionType.manual && _manualAmounts.isNotEmpty) {
        manualAmounts = Map.from(_manualAmounts);
      }

      await ref
          .read(expenseNotifierProvider.notifier)
          .addExpense(
            groupId: widget.group.id,
            paidBy: currentUser.uid,
            description: _descriptionController.text.trim(),
            amount: amount,
            category: _selectedCategoryId!,
            date: DateTime.now(),
            sharedBy: _selectedMemberIds,
            manualAmounts: manualAmounts,
            imageUrl: imageUrl,
          );

      if (mounted) {
        ErrorSnackBar.showSuccess(context, 'Masraf başarıyla eklendi!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickReceiptImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (result != null) {
      setState(() => _receiptImage = result);
    }
  }

  void _removeReceiptImage() {
    setState(() => _receiptImage = null);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder:
            (context, scrollController) => Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Masraf Ekle', style: AppTextStyles.h3.copyWith(color: colorScheme.onSurface)),
                          IconButton(
                            icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Grup kapalı uyarısı
                            if (!widget.group.isActive) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.warning),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Grup kapalı. Yeni masraf eklenemez.',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.warning,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sectionMargin),
                            ],
                            // Form içeriği - grup kapalıysa devre dışı
                            IgnorePointer(
                              ignoring: !widget.group.isActive,
                              child: Opacity(
                                opacity: widget.group.isActive ? 1.0 : 0.5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Tutar
                                    CustomTextField(
                                      controller: _amountController,
                                      label: 'Tutar (₺)',
                                      hint: '0.00',
                                      prefixIcon: Icons.currency_lira,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Tutar gereklidir';
                                        }
                                        final amount = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
                                        if (amount <= 0) {
                                          return 'Tutar 0\'dan büyük olmalıdır';
                                        }
                                        return null;
                                      },
                                      textInputAction: TextInputAction.next,
                                    ),
                                    const SizedBox(height: AppSpacing.textSpacing * 2),

                                    // Açıklama
                                    CustomTextField(
                                      controller: _descriptionController,
                                      label: 'Açıklama',
                                      hint: 'Masraf açıklaması',
                                      prefixIcon: Icons.description,
                                      maxLines: 3,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Açıklama gereklidir';
                                        }
                                        return null;
                                      },
                                      textInputAction: TextInputAction.next,
                                    ),
                                    const SizedBox(height: AppSpacing.textSpacing * 2),

                                    // Fotoğraf
                                    _buildReceiptSection(colorScheme),
                                    const SizedBox(height: AppSpacing.textSpacing * 2),

                                    // Kategori
                                    CategorySelector(
                                      selectedCategoryId: _selectedCategoryId,
                                      onCategorySelected:
                                          (categoryId) => setState(() => _selectedCategoryId = categoryId),
                                    ),
                                    const SizedBox(height: AppSpacing.sectionMargin),

                                    // Harcamaya dahil edilecek kişiler
                                    MemberSelector(
                                      selectedMemberIds: _selectedMemberIds,
                                      onMembersChanged: (memberIds) {
                                        setState(() {
                                          _selectedMemberIds = memberIds;
                                          if (_distributionType == DistributionType.manual) {
                                            // Manuel dağılım için yeni üyeler için 0.00 ekle (otomatik bölme yok)
                                            for (final memberId in memberIds) {
                                              if (!_manualAmounts.containsKey(memberId)) {
                                                _manualAmounts[memberId] = 0.0;
                                              }
                                            }
                                            // Çıkarılan üyeleri temizle
                                            _manualAmounts.removeWhere((key, value) => !memberIds.contains(key));
                                          }
                                        });
                                      },
                                      availableMemberIds: widget.group.memberIds,
                                    ),
                                    const SizedBox(height: AppSpacing.sectionMargin),

                                    // Dağıtım Tipi
                                    DistributionTypeSelector(
                                      selectedType: _distributionType,
                                      onTypeSelected: (type) {
                                        setState(() {
                                          _distributionType = type;
                                          if (type == DistributionType.equal) {
                                            _manualAmounts.clear();
                                          } else {
                                            // Manuel dağılım için başlangıç değerleri - kullanıcı kendisi belirleyecek
                                            _manualAmounts = {for (final memberId in _selectedMemberIds) memberId: 0.0};
                                          }
                                        });
                                      },
                                    ),
                                    const SizedBox(height: AppSpacing.sectionMargin),

                                    // Manuel dağılım input'u
                                    if (_distributionType == DistributionType.manual && _selectedMemberIds.isNotEmpty)
                                      ManualDistributionInput(
                                        selectedMemberIds: _selectedMemberIds,
                                        totalAmount:
                                            double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0,
                                        memberAmounts: _manualAmounts,
                                        onAmountsChanged: (amounts) => setState(() => _manualAmounts = amounts),
                                      ),

                                    const SizedBox(height: AppSpacing.sectionMargin),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Footer with button
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: CustomButton(
                        text: 'Masraf Ekle',
                        onPressed: (_isLoading || !widget.group.isActive) ? null : _createExpense,
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildReceiptSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fiş / Fotoğraf (Opsiyonel)', style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.textSpacing),
        if (_receiptImage != null) ...[
          Stack(
            children: [
              GestureDetector(
                onTap: () => _showImagePreview(Image.file(File(_receiptImage!.path)).image),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(_receiptImage!.path), height: 180, width: double.infinity, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: colorScheme.surface,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    color: colorScheme.error,
                    onPressed: _removeReceiptImage,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CustomButton(text: 'Fotoğrafı Değiştir', icon: Icons.photo_library, onPressed: _pickReceiptImage, height: 48),
        ] else ...[
          OutlinedButton.icon(
            onPressed: _pickReceiptImage,
            icon: const Icon(Icons.photo_camera),
            label: const Text('Fotoğraf Ekle'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
        ],
      ],
    );
  }

  void _showImagePreview(ImageProvider provider) {
    showDialog(
      context: context,
      builder:
          (context) => GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              color: Colors.black.withValues(alpha: 0.8),
              alignment: Alignment.center,
              child: InteractiveViewer(child: Image(image: provider)),
            ),
          ),
    );
  }
}
