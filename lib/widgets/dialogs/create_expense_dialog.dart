import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';
import '../../models/group_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/forms/custom_text_field.dart';
import '../../widgets/forms/custom_button.dart';
import '../../widgets/common/category_selector.dart';
import '../../widgets/common/member_selector.dart';
import '../../widgets/common/manual_distribution_input.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/common/payment_type_selector.dart';

/// Masraf ekleme dialog'u
class CreateExpenseDialog extends ConsumerStatefulWidget {
  final GroupModel group;

  const CreateExpenseDialog({
    super.key,
    required this.group,
  });

  static Future<void> show(BuildContext context, GroupModel group) async {
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
    super.dispose();
  }

  Future<void> _createExpense() async {
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
      // Manuel dağılım varsa manualAmounts'ı gönder
      Map<String, double>? manualAmounts;
      if (_distributionType == DistributionType.manual && _manualAmounts.isNotEmpty) {
        manualAmounts = Map.from(_manualAmounts);
      }

      await ref.read(expenseNotifierProvider.notifier).addExpense(
            groupId: widget.group.id,
            paidBy: currentUser.uid,
            description: _descriptionController.text.trim(),
            amount: amount,
            category: _selectedCategoryId!,
            date: DateTime.now(),
            sharedBy: _selectedMemberIds,
            manualAmounts: manualAmounts,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Padding(
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
                        'Masraf Ekle',
                        style: AppTextStyles.h3,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
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

                        // Kategori
                        CategorySelector(
                          selectedCategoryId: _selectedCategoryId,
                          onCategorySelected: (categoryId) => setState(() => _selectedCategoryId = categoryId),
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
                                _manualAmounts = {
                                  for (final memberId in _selectedMemberIds) memberId: 0.0
                                };
                              }
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.sectionMargin),

                        // Manuel dağılım input'u
                        if (_distributionType == DistributionType.manual && _selectedMemberIds.isNotEmpty)
                          ManualDistributionInput(
                            selectedMemberIds: _selectedMemberIds,
                            totalAmount: double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0,
                            memberAmounts: _manualAmounts,
                            onAmountsChanged: (amounts) => setState(() => _manualAmounts = amounts),
                          ),

                        const SizedBox(height: AppSpacing.sectionMargin),
                      ],
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
                    text: 'Masraf Ekle',
                    onPressed: _isLoading ? null : _createExpense,
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
}

