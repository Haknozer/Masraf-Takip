import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';
import '../../models/expense_model.dart';
import '../../models/group_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/common/category_selector.dart';
import '../../widgets/common/member_selector.dart';
import '../../widgets/common/async_value_builder.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/common/manual_distribution_input.dart';
import '../../widgets/common/payment_type_selector.dart';
import '../../widgets/forms/custom_button.dart';
import '../../widgets/forms/custom_text_field.dart';

/// Masraf düzenleme dialog'u
class EditExpenseDialog extends ConsumerStatefulWidget {
  final String expenseId;

  const EditExpenseDialog({
    super.key,
    required this.expenseId,
  });

  static Future<void> show(BuildContext context, String expenseId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditExpenseDialog(expenseId: expenseId),
    );
  }

  @override
  ConsumerState<EditExpenseDialog> createState() => _EditExpenseDialogState();
}

class _EditExpenseDialogState extends ConsumerState<EditExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  XFile? _receiptImage;

  String? _selectedCategoryId;
  DistributionType? _distributionType;
  List<String> _selectedMemberIds = [];
  Map<String, double> _manualAmounts = {};
  String? _imageUrl;
  bool _imageRemoved = false;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _receiptImage = null;
    super.dispose();
  }

  void _initializeForm(ExpenseModel expense, GroupModel group) {
    if (_isInitialized) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _amountController.text = expense.amount.toStringAsFixed(2);
        _descriptionController.text = expense.description;
        _selectedCategoryId = expense.category;
        _selectedMemberIds = List.from(expense.sharedBy);
        _imageUrl = expense.imageUrl;
        _imageRemoved = false;
        _receiptImage = null;

        // Dağılım tipini belirle
        if (expense.manualAmounts != null && expense.manualAmounts!.isNotEmpty) {
          _distributionType = DistributionType.manual;
          _manualAmounts = Map.from(expense.manualAmounts!);
        } else {
          _distributionType = DistributionType.equal;
        }

        setState(() => _isInitialized = true);
      }
    });
  }

  Future<void> _updateExpense(ExpenseModel expense, GroupModel group) async {
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

    // Sadece masrafı ekleyen kişi düzenleyebilir
    final canEdit = expense.paidBy == currentUser.uid ||
        (expense.paidAmounts?.containsKey(currentUser.uid) ?? false);
    if (!canEdit) {
      ErrorSnackBar.show(context, 'Bu masrafı sadece masrafı ekleyen kişi düzenleyebilir');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Manuel dağılım varsa manualAmounts'ı gönder
      Map<String, double>? manualAmounts;
      if (_distributionType == DistributionType.manual && _manualAmounts.isNotEmpty) {
        manualAmounts = Map.from(_manualAmounts);
      }

      String? imageUrl = _imageUrl;
      bool imageUpdated = _imageRemoved;

      if (_receiptImage != null) {
        final fileName = '${expense.groupId}_${expense.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageUrl = await FirebaseService.uploadFile(
          path: 'expense_receipts/$fileName',
          file: _receiptImage!,
        );
        imageUpdated = true;
      } else if (_imageRemoved) {
        imageUrl = null;
      }

      await ref.read(expenseNotifierProvider.notifier).updateExpense(
            expenseId: expense.id,
            description: _descriptionController.text.trim(),
            amount: amount,
            category: _selectedCategoryId!,
            date: expense.date, // Tarih değiştirilemez
            paidBy: expense.paidBy, // Ödeyen kişi değiştirilemez
            sharedBy: _selectedMemberIds,
            manualAmounts: manualAmounts,
            imageUrl: imageUrl,
            imageUpdated: imageUpdated,
          );

      if (mounted) {
        ErrorSnackBar.showSuccess(context, 'Masraf başarıyla güncellendi!');
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
      setState(() {
        _receiptImage = result;
        _imageRemoved = false;
      });
    }
  }

  void _removeReceiptImage() {
    setState(() {
      if (_receiptImage != null) {
        _receiptImage = null;
      } else if (_imageUrl != null) {
        _imageUrl = null;
        _imageRemoved = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider(widget.expenseId));
    final currentUser = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => AsyncValueBuilder<ExpenseModel?>(
          value: expenseState,
          dataBuilder: (context, expense) {
            if (expense == null) {
              return const Center(child: Text('Masraf bulunamadı'));
            }

            final groupState = ref.watch(groupProvider(expense.groupId));
            return groupState.when(
              data: (group) {
                if (group == null) {
                  return const Center(child: Text('Grup bulunamadı'));
                }

                // Sadece masrafı ekleyen kişi düzenleyebilir
                final canEdit = currentUser != null && expense.paidBy == currentUser.uid;

                if (!_isInitialized) {
                  _initializeForm(expense, group);
                }

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
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
                            color: AppColors.grey,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Masraf Düzenle',
                                style: AppTextStyles.h3,
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                        if (!canEdit)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Bu masrafı sadece masrafı ekleyen kişi düzenleyebilir. Bilgileri görüntüleyebilirsiniz.',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ),

                        // Content
                        Expanded(
                          child: Opacity(
                            opacity: canEdit ? 1 : 0.65,
                            child: SingleChildScrollView(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                    readOnly: !canEdit,
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
                                    readOnly: !canEdit,
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: AppSpacing.textSpacing * 2),

                                  _buildReceiptSection(canEdit, colorScheme),
                                  const SizedBox(height: AppSpacing.textSpacing * 2),

                                  // Kategori
                                  IgnorePointer(
                                    ignoring: !canEdit,
                                    child: CategorySelector(
                                      selectedCategoryId: _selectedCategoryId,
                                      onCategorySelected: (categoryId) =>
                                          setState(() => _selectedCategoryId = categoryId),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sectionMargin),

                                  // Harcamaya dahil edilecek kişiler
                                  IgnorePointer(
                                    ignoring: !canEdit,
                                    child: MemberSelector(
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
                                      availableMemberIds: group.memberIds,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sectionMargin),

                                  // Dağıtım Tipi
                                  IgnorePointer(
                                    ignoring: !canEdit,
                                    child: DistributionTypeSelector(
                                      selectedType: _distributionType,
                                      onTypeSelected: (type) {
                                        setState(() {
                                          _distributionType = type;
                                          if (type == DistributionType.equal) {
                                            _manualAmounts.clear();
                                          } else {
                                            // Manuel dağılım için başlangıç değerleri - kullanıcı kendisi belirleyecek
                                            _manualAmounts = {
                                              for (final memberId in _selectedMemberIds)
                                                memberId: _manualAmounts[memberId] ?? 0.0
                                            };
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sectionMargin),

                                  // Manuel dağılım input'u
                                  if (_distributionType == DistributionType.manual && _selectedMemberIds.isNotEmpty)
                                    IgnorePointer(
                                      ignoring: !canEdit,
                                      child: ManualDistributionInput(
                                        selectedMemberIds: _selectedMemberIds,
                                        totalAmount:
                                            double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0,
                                        memberAmounts: _manualAmounts,
                                        onAmountsChanged: (amounts) => setState(() => _manualAmounts = amounts),
                                      ),
                                    ),

                                  const SizedBox(height: AppSpacing.sectionMargin),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Footer with button
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, -5),
                              ),
                            ],
                          ),
                          child: CustomButton(
                            text: 'Masrafı Güncelle',
                            onPressed: (!canEdit || _isLoading) ? null : () => _updateExpense(expense, group),
                            isLoading: _isLoading,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Hata: $e')),
            );
          },
          loadingBuilder: (context) => const Center(child: CircularProgressIndicator()),
          errorBuilder: (context, error, stack) => Center(child: Text('Hata: $error')),
        ),
      ),
    );
  }

  Widget _buildReceiptSection(bool canEdit, ColorScheme colorScheme) {
    final hasNewImage = _receiptImage != null;
    final hasExistingImage = _imageUrl != null && _imageUrl!.isNotEmpty;

    if (!canEdit && !hasNewImage && !hasExistingImage) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fiş / Fotoğraf (Opsiyonel)', style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.textSpacing),
        if (hasNewImage) ...[
          Stack(
            children: [
              GestureDetector(
                onTap: () => _showImagePreview(Image.file(File(_receiptImage!.path)).image),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_receiptImage!.path),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (canEdit)
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
        ] else if (hasExistingImage) ...[
          Stack(
            children: [
              GestureDetector(
                onTap: () => _showImagePreview(Image.network(_imageUrl!).image),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _imageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (canEdit)
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
        ] else if (!canEdit) ...[
          Text(
            'Fotoğraf eklenmemiş',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
        if (canEdit)
          OutlinedButton.icon(
            onPressed: _pickReceiptImage,
            icon: const Icon(Icons.photo_camera),
            label: Text(hasNewImage || hasExistingImage ? 'Fotoğrafı Değiştir' : 'Fotoğraf Ekle'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
      ],
    );
  }

  void _showImagePreview(ImageProvider provider) {
    showDialog(
      context: context,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black.withOpacity(0.8),
          alignment: Alignment.center,
          child: InteractiveViewer(
            child: Image(image: provider),
          ),
        ),
      ),
    );
  }
}

