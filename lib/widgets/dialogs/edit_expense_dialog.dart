import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';
import '../../models/expense_model.dart';
import '../../models/group_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../widgets/forms/custom_text_field.dart';
import '../../widgets/forms/custom_button.dart';
import '../../widgets/common/category_selector.dart';
import '../../widgets/common/member_selector.dart';
import '../../widgets/common/manual_distribution_input.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/common/async_value_builder.dart';
import '../../widgets/common/payment_type_selector.dart';

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

  String? _selectedCategoryId;
  DistributionType? _distributionType;
  List<String> _selectedMemberIds = [];
  Map<String, double> _manualAmounts = {};
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
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
    if (expense.paidBy != currentUser.uid) {
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

      await ref.read(expenseNotifierProvider.notifier).updateExpense(
            expenseId: expense.id,
            description: _descriptionController.text.trim(),
            amount: amount,
            category: _selectedCategoryId!,
            date: expense.date, // Tarih değiştirilemez
            paidBy: expense.paidBy, // Ödeyen kişi değiştirilemez
            sharedBy: _selectedMemberIds,
            manualAmounts: manualAmounts,
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


  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider(widget.expenseId));
    final currentUser = ref.watch(currentUserProvider);

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
                if (currentUser == null || expense.paidBy != currentUser.uid) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: 16),
                        Text(
                          'Bu masrafı sadece masrafı ekleyen kişi düzenleyebilir',
                          style: AppTextStyles.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Kapat'),
                        ),
                      ],
                    ),
                  );
                }

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
                                  availableMemberIds: group.memberIds,
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
                                          for (final memberId in _selectedMemberIds) memberId: _manualAmounts[memberId] ?? 0.0
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
                            text: 'Masrafı Güncelle',
                            onPressed: _isLoading ? null : () => _updateExpense(expense, group),
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
}

