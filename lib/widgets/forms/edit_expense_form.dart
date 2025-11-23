import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_spacing.dart';
import '../../models/expense_model.dart';
import '../../models/group_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../widgets/forms/custom_text_field.dart';
import '../../widgets/forms/custom_button.dart';
import '../../widgets/common/category_selector.dart';
import '../../widgets/common/payment_type_selector.dart';
import '../../widgets/common/member_selector.dart';
import '../../widgets/common/manual_distribution_input.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/common/async_value_builder.dart';
import '../../widgets/dialogs/delete_expense_dialog.dart';
import '../../controllers/expense_controller.dart';
import '../../utils/date_utils.dart' as DateUtils;

class EditExpenseForm extends ConsumerStatefulWidget {
  final String expenseId;
  final VoidCallback onSuccess;
  final VoidCallback? onDelete;

  const EditExpenseForm({
    super.key,
    required this.expenseId,
    required this.onSuccess,
    this.onDelete,
  });

  @override
  ConsumerState<EditExpenseForm> createState() => _EditExpenseFormState();
}

class _EditExpenseFormState extends ConsumerState<EditExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();

  String? _selectedCategoryId;
  DateTime? _selectedDate;
  PaymentType? _paymentType;
  DistributionType? _distributionType;
  List<String> _selectedMemberIds = [];
  String? _selectedPayerId;
  Map<String, double> _manualAmounts = {};
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _initializeForm(ExpenseModel expense, GroupModel group) {
    if (_isInitialized) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _amountController.text = expense.amount.toStringAsFixed(2);
        _descriptionController.text = expense.description;
        _selectedCategoryId = expense.category;
        _selectedDate = expense.date;
        _dateController.text = DateUtils.AppDateUtils.formatDate(expense.date);
        _selectedMemberIds = List.from(expense.sharedBy);

        // Ödeme tipini belirle
        if (expense.sharedBy.length == 1) {
          _paymentType = PaymentType.fullPayment;
          _selectedPayerId = expense.sharedBy.first;
        } else {
          _paymentType = PaymentType.sharedPayment;
          _selectedPayerId = expense.paidBy;

          // Manuel dağılım kontrolü
          if (expense.manualAmounts != null &&
              expense.manualAmounts!.isNotEmpty) {
            _distributionType = DistributionType.manual;
            _manualAmounts = Map.from(expense.manualAmounts!);
          } else {
            _distributionType = DistributionType.equal;
          }
        }

        setState(() => _isInitialized = true);
      }
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateUtils.AppDateUtils.formatDate(picked);
      });
    }
  }

  Future<void> _updateExpense(ExpenseModel expense, GroupModel group) async {
    if (!_formKey.currentState!.validate()) return;

    // Validasyonlar
    if (_selectedCategoryId == null) {
      ErrorSnackBar.showWarning(context, 'Lütfen bir kategori seçin');
      return;
    }

    if (_paymentType == null) {
      ErrorSnackBar.showWarning(context, 'Lütfen ödeme tipini seçin');
      return;
    }

    if (_selectedDate == null) {
      ErrorSnackBar.showWarning(context, 'Lütfen bir tarih seçin');
      return;
    }

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    if (amount <= 0) {
      ErrorSnackBar.showWarning(context, 'Tutar 0\'dan büyük olmalıdır');
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ErrorSnackBar.show(context, 'Giriş yapmanız gerekiyor');
      return;
    }

    // Paylaşım mantığına göre sharedBy listesini oluştur
    List<String> sharedBy = [];

    if (_paymentType == PaymentType.fullPayment) {
      if (_selectedPayerId == null) {
        ErrorSnackBar.showWarning(context, 'Lütfen ödeyen kişiyi seçin');
        return;
      }
      sharedBy = [_selectedPayerId!];
    } else {
      if (_selectedMemberIds.isEmpty) {
        ErrorSnackBar.showWarning(context, 'Lütfen en az bir kişi seçin');
        return;
      }

      if (_distributionType == null) {
        ErrorSnackBar.showWarning(context, 'Lütfen dağılım tipini seçin');
        return;
      }

      if (_distributionType == DistributionType.manual) {
        final total = _manualAmounts.values.fold(0.0, (sum, amt) => sum + amt);
        if ((total - amount).abs() > 0.01) {
          ErrorSnackBar.showWarning(
            context,
            'Manuel dağılım toplamı tutara eşit olmalıdır',
          );
          return;
        }
      }

      sharedBy = List.from(_selectedMemberIds);
    }

    setState(() => _isLoading = true);

    try {
      // Manuel dağılım varsa manualAmounts'ı gönder
      Map<String, double>? manualAmounts;
      if (_paymentType == PaymentType.sharedPayment &&
          _distributionType == DistributionType.manual &&
          _manualAmounts.isNotEmpty) {
        manualAmounts = Map.from(_manualAmounts);
      }

      // paidBy'ı belirle
      String paidBy;
      if (_paymentType == PaymentType.fullPayment) {
        paidBy = _selectedPayerId ?? currentUser.uid;
      } else {
        paidBy = _selectedPayerId ?? currentUser.uid;
      }

      await ref
          .read(expenseNotifierProvider.notifier)
          .updateExpense(
            expenseId: widget.expenseId,
            description: _descriptionController.text.trim(),
            amount: amount,
            category: _selectedCategoryId!,
            date: _selectedDate!,
            sharedBy: sharedBy,
            paidBy: paidBy,
            manualAmounts: manualAmounts,
          );

      if (mounted) {
        ErrorSnackBar.showSuccess(context, 'Masraf başarıyla güncellendi!');
        widget.onSuccess();
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

    return AsyncValueBuilder<ExpenseModel?>(
      value: expenseState,
      dataBuilder: (context, expense) {
        if (expense == null) {
          return const Center(child: Text('Masraf bulunamadı'));
        }

        final groupState = ref.watch(groupProvider(expense.groupId));

        return AsyncValueBuilder<GroupModel?>(
          value: groupState,
          dataBuilder: (context, group) {
            if (group == null) {
              return const Center(child: Text('Grup bulunamadı'));
            }

            _initializeForm(expense, group);

            return Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tutar
                  CustomTextField(
                    controller: _amountController,
                    label: 'Tutar (TL)',
                    hint: '0.00',
                    prefixIcon: Icons.currency_lira,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Tutar gereklidir';
                      }
                      final amount =
                          double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
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
                    onCategorySelected:
                        (categoryId) =>
                            setState(() => _selectedCategoryId = categoryId),
                  ),
                  const SizedBox(height: AppSpacing.sectionMargin),

                  // Tarih
                  GestureDetector(
                    onTap: _selectDate,
                    child: CustomTextField(
                      controller: _dateController,
                      label: 'Tarih',
                      hint: 'Tarih seçin',
                      prefixIcon: Icons.calendar_today,
                      readOnly: true,
                      onTap: _selectDate,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.textSpacing * 2),

                  // Ödeme Tipi
                  PaymentTypeSelector(
                    selectedType: _paymentType,
                    onTypeSelected: (type) {
                      setState(() {
                        _paymentType = type;
                        if (type == PaymentType.fullPayment) {
                          _distributionType = null;
                          _manualAmounts.clear();
                        } else {
                          _distributionType = DistributionType.equal;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.sectionMargin),

                  // Ödeme tipine göre içerik
                  if (_paymentType == PaymentType.fullPayment) ...[
                    MemberSelector(
                      selectedMemberIds:
                          _selectedPayerId != null ? [_selectedPayerId!] : [],
                      onMembersChanged: (memberIds) {
                        setState(
                          () =>
                              _selectedPayerId =
                                  memberIds.isNotEmpty ? memberIds.first : null,
                        );
                      },
                      availableMemberIds: group.memberIds,
                    ),
                  ] else if (_paymentType == PaymentType.sharedPayment) ...[
                    MemberSelector(
                      selectedMemberIds: _selectedMemberIds,
                      onMembersChanged: (memberIds) {
                        setState(() {
                          _selectedMemberIds = memberIds;
                          if (_distributionType == DistributionType.manual) {
                            for (final memberId in memberIds) {
                              if (!_manualAmounts.containsKey(memberId)) {
                                _manualAmounts[memberId] = 0.0;
                              }
                            }
                            _manualAmounts.removeWhere(
                              (key, value) => !memberIds.contains(key),
                            );
                          }
                        });
                      },
                      availableMemberIds: group.memberIds,
                    ),
                    const SizedBox(height: AppSpacing.sectionMargin),

                    DistributionTypeSelector(
                      selectedType: _distributionType,
                      onTypeSelected: (type) {
                        setState(() {
                          _distributionType = type;
                          if (type == DistributionType.equal) {
                            _manualAmounts.clear();
                          } else {
                            final amount =
                                double.tryParse(
                                  _amountController.text.replaceAll(',', '.'),
                                ) ??
                                0.0;
                            final perPerson =
                                _selectedMemberIds.isNotEmpty
                                    ? amount / _selectedMemberIds.length
                                    : 0.0;
                            _manualAmounts = {
                              for (final memberId in _selectedMemberIds)
                                memberId: perPerson,
                            };
                          }
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.sectionMargin),

                    if (_distributionType == DistributionType.manual &&
                        _selectedMemberIds.isNotEmpty)
                      ManualDistributionInput(
                        selectedMemberIds: _selectedMemberIds,
                        totalAmount:
                            double.tryParse(
                              _amountController.text.replaceAll(',', '.'),
                            ) ??
                            0.0,
                        memberAmounts: _manualAmounts,
                        onAmountsChanged:
                            (amounts) =>
                                setState(() => _manualAmounts = amounts),
                      ),
                  ],

                  const SizedBox(height: AppSpacing.sectionMargin),

                  // Güncelle Butonu
                  CustomButton(
                    text: 'Masrafı Güncelle',
                    onPressed:
                        _isLoading
                            ? null
                            : () => _updateExpense(expense, group),
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: AppSpacing.textSpacing),

                  // Sil Butonu
                  CustomButton(
                    text: 'Masrafı Sil',
                    onPressed:
                        _isLoading ? null : () => _deleteExpense(expense),
                    isLoading: false,
                    isSecondary: true,
                    icon: Icons.delete,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteExpense(ExpenseModel expense) async {
    // Silme onay dialogu göster
    final confirmed = await DeleteExpenseDialog.show(
      context,
      expenseDescription: expense.description,
      expenseAmount: expense.amount,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await ExpenseController.deleteExpense(ref, widget.expenseId);

      if (mounted) {
        ErrorSnackBar.showSuccess(context, 'Masraf başarıyla silindi!');
        if (widget.onDelete != null) {
          widget.onDelete!();
        } else {
          widget.onSuccess();
        }
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
}
