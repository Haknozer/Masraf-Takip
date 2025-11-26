import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/app_spacing.dart';
import '../../models/group_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/forms/custom_text_field.dart';
import '../../widgets/forms/custom_button.dart';
import '../../widgets/common/category_selector.dart';
import '../../widgets/common/payment_type_selector.dart';
import '../../widgets/selectors/distribution_type_selector.dart';
import '../../widgets/common/member_selector.dart';
import '../../widgets/common/paid_amounts_input.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/dialogs/expense/expense_receipt_section.dart';
import '../../utils/validators/expense_validator.dart';
import '../../utils/date_utils.dart' as app_date_utils;
import 'sections/expense_distribution_section.dart';

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
  XFile? _receiptImage;

  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  PaymentType? _paymentType;
  DistributionType? _distributionType;
  List<String> _selectedMemberIds = [];
  String? _selectedPayerId; // Tamamını ödeyen kişi
  Map<String, double> _manualAmounts = {}; // Manuel dağılım için
  Map<String, double> _paidAmounts = {}; // Paylaşımlı ödemede kim ne kadar ödedi

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
      _paidAmounts[currentUser.uid] = 0.0;
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

  Future<void> _createExpense() async {
    // Grup kapalı kontrolü
    if (!widget.group.isActive) {
      ErrorSnackBar.showWarning(context, 'Grup kapalı. Yeni masraf eklenemez.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

    // Temel validasyonlar (Validator sınıfı kullanılarak)
    String? error = ExpenseValidator.validateForm(
      amount: amount,
      categoryId: _selectedCategoryId,
      selectedMemberIds:
          _paymentType == PaymentType.fullPayment
              ? (_selectedPayerId != null ? [_selectedPayerId!] : []) // Tam ödemede sadece ödeyen kişi önemli
              : _selectedMemberIds, // Paylaşımlı ödemede seçili üyeler
      distributionType: _distributionType ?? DistributionType.equal, // Varsayılan equal
      manualAmounts: _manualAmounts,
    );

    if (error != null) {
      // Validator genel hataları yakaladıysa göster (Ancak PaymentType ve PaidAmounts özel durumları aşağıda)
      // Burada özel durumları filtreleyip validator'a bırakmak daha doğru
    }

    // Özel Validasyonlar (Validator sınıfında olmayanlar)
    if (_selectedCategoryId == null) {
      ErrorSnackBar.showWarning(context, 'Lütfen bir kategori seçin');
      return;
    }

    if (_paymentType == null) {
      ErrorSnackBar.showWarning(context, 'Lütfen ödeme tipini seçin');
      return;
    }

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
    Map<String, double>? paidByAmounts;

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
        final manualError = ExpenseValidator.validateManualDistribution(
          totalAmount: amount,
          manualAmounts: _manualAmounts,
        );
        if (manualError != null) {
          ErrorSnackBar.showWarning(context, manualError);
          return;
        }
      }

      sharedBy = List.from(_selectedMemberIds);

      final cleanedPaidAmounts = Map<String, double>.fromEntries(
        _paidAmounts.entries.where((entry) => entry.value > 0),
      );
      if (cleanedPaidAmounts.isEmpty) {
        ErrorSnackBar.showWarning(context, 'Lütfen ödeyen kişilerin tutarlarını girin');
        return;
      }
      final paidTotal = cleanedPaidAmounts.values.fold(0.0, (sum, value) => sum + value);
      if ((paidTotal - amount).abs() > 0.01) {
        ErrorSnackBar.showWarning(context, 'Ödeme tutarlarının toplamı ${amount.toStringAsFixed(2)} TL olmalı');
        return;
      }
      paidByAmounts = cleanedPaidAmounts;
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
      if (_paymentType == PaymentType.sharedPayment &&
          _distributionType == DistributionType.manual &&
          _manualAmounts.isNotEmpty) {
        manualAmounts = Map.from(_manualAmounts);
      }

      await ref
          .read(expenseNotifierProvider.notifier)
          .addExpense(
            groupId: widget.group.id,
            paidBy:
                (_paymentType == PaymentType.fullPayment
                    ? _selectedPayerId ?? currentUser.uid
                    : (paidByAmounts?.entries.reduce((a, b) => a.value >= b.value ? a : b).key ?? currentUser.uid)),
            description: _descriptionController.text.trim(),
            amount: amount,
            category: _selectedCategoryId!,
            date: _selectedDate,
            sharedBy: sharedBy,
            manualAmounts: manualAmounts,
            paidAmounts: paidByAmounts,
            imageUrl: imageUrl,
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
    final totalAmount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
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

          // Fotoğraf
          ExpenseReceiptSection(
            receiptImage: _receiptImage,
            onPickImage: _pickReceiptImage,
            onRemoveImage: _removeReceiptImage,
            onShowPreview: _showImagePreview,
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
                  _paidAmounts.clear();
                } else {
                  // Paylaşımlı ödeme için varsayılan olarak eşit dağılım
                  _distributionType = DistributionType.equal;
                  if (_paidAmounts.isEmpty) {
                    final currentUser = ref.read(currentUserProvider);
                    if (currentUser != null) {
                      _paidAmounts[currentUser.uid] =
                          double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
                    }
                  }
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
            // Ödeyenlerin girişi
            PaidAmountsInput(
              memberIds: widget.group.memberIds,
              totalAmount: totalAmount,
              paidAmounts: _paidAmounts,
              onChanged: (amounts) => setState(() => _paidAmounts = amounts),
            ),
            const SizedBox(height: AppSpacing.sectionMargin),

            // Paylaşımlı ödeme: Dağılım Bölümü
            ExpenseDistributionSection(
              selectedMemberIds: _selectedMemberIds,
              availableMemberIds: widget.group.memberIds,
              onMembersChanged: (memberIds) => setState(() => _selectedMemberIds = memberIds),
              distributionType: _distributionType,
              onDistributionTypeChanged: (type) => setState(() => _distributionType = type),
              manualAmounts: _manualAmounts,
              onManualAmountsChanged: (amounts) => setState(() => _manualAmounts = amounts),
              totalAmount: totalAmount,
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
