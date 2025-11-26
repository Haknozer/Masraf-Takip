import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_spacing.dart';
import '../../models/group_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/forms/custom_text_field.dart';
import '../../widgets/forms/custom_button.dart';
import '../../widgets/common/category_selector.dart';
import '../../widgets/common/payment_type_selector.dart';
import '../../widgets/common/member_selector.dart';
import '../../widgets/common/manual_distribution_input.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../utils/date_utils.dart' as app_date_utils;

class CreateExpenseForm extends ConsumerStatefulWidget {
  final GroupModel group;
  final VoidCallback onSuccess;

  const CreateExpenseForm({super.key, required this.group, required this.onSuccess});

  @override
  ConsumerState<CreateExpenseForm> createState() => _CreateExpenseFormState();
}

class _CreateExpenseFormState extends ConsumerState<CreateExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  PaymentType? _paymentType;
  DistributionType? _distributionType;
  List<String> _selectedMemberIds = [];
  String? _selectedPayerId; // Tamamını ödeyen kişi
  Map<String, double> _manualAmounts = {}; // Manuel dağılım için

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Varsayılan olarak tüm grup üyelerini seç
    _selectedMemberIds = List.from(widget.group.memberIds);
    // Varsayılan olarak mevcut kullanıcıyı ödeyen olarak seç
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      _selectedPayerId = currentUser.uid;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _createExpense() async {
    // Grup kapalı kontrolü
    if (!widget.group.isActive) {
      ErrorSnackBar.showWarning(context, 'Grup kapalı. Yeni masraf eklenemez.');
      return;
    }

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

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
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
      // Tamamını ödeyen: Sadece ödeyen kişi
      if (_selectedPayerId == null) {
        ErrorSnackBar.showWarning(context, 'Lütfen ödeyen kişiyi seçin');
        return;
      }
      sharedBy = [_selectedPayerId!];
    } else {
      // Paylaşımlı ödeme
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

      await ref
          .read(expenseNotifierProvider.notifier)
          .addExpense(
            groupId: widget.group.id,
            paidBy: _selectedPayerId ?? currentUser.uid,
            description: _descriptionController.text.trim(),
            amount: amount,
            category: _selectedCategoryId!,
            date: _selectedDate,
            sharedBy: sharedBy,
            manualAmounts: manualAmounts,
          );

      if (mounted) {
        ErrorSnackBar.showSuccess(context, 'Masraf başarıyla eklendi!');
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

          // Tarih
          GestureDetector(
            onTap: _selectDate,
            child: CustomTextField(
              controller: TextEditingController(text: app_date_utils.AppDateUtils.formatDate(_selectedDate)),
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
                  // Paylaşımlı ödeme için varsayılan olarak eşit dağılım
                  _distributionType = DistributionType.equal;
                }
              });
            },
          ),
          const SizedBox(height: AppSpacing.sectionMargin),

          // Ödeme tipine göre içerik
          if (_paymentType == PaymentType.fullPayment) ...[
            // Tamamını ödeyen: Kişi seçimi
            MemberSelector(
              selectedMemberIds: _selectedPayerId != null ? [_selectedPayerId!] : [],
              onMembersChanged: (memberIds) {
                setState(() => _selectedPayerId = memberIds.isNotEmpty ? memberIds.first : null);
              },
              availableMemberIds: widget.group.memberIds,
            ),
          ] else if (_paymentType == PaymentType.sharedPayment) ...[
            // Paylaşımlı ödeme: Üye seçimi
            MemberSelector(
              selectedMemberIds: _selectedMemberIds,
              onMembersChanged: (memberIds) {
                setState(() {
                  _selectedMemberIds = memberIds;
                  if (_distributionType == DistributionType.manual) {
                    // Manuel dağılım için yeni üyeler için 0.00 ekle
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

            // Dağılım Tipi
            DistributionTypeSelector(
              selectedType: _distributionType,
              onTypeSelected: (type) {
                setState(() {
                  _distributionType = type;
                  if (type == DistributionType.equal) {
                    _manualAmounts.clear();
                  } else {
                    // Manuel dağılım için başlangıç değerleri
                    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
                    final perPerson = _selectedMemberIds.isNotEmpty ? amount / _selectedMemberIds.length : 0.0;
                    _manualAmounts = {for (final memberId in _selectedMemberIds) memberId: perPerson};
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
          ],

          const SizedBox(height: AppSpacing.sectionMargin),

          // Masraf Ekle Butonu
          CustomButton(text: 'Masraf Ekle', onPressed: _isLoading ? null : _createExpense, isLoading: _isLoading),
        ],
      ),
    );
  }
}
