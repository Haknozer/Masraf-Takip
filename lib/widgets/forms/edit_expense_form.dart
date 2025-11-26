import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';
import '../../models/expense_model.dart';
import '../../models/group_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/forms/custom_text_field.dart';
import '../../widgets/forms/custom_button.dart';
import '../../widgets/common/category_selector.dart';
import '../../widgets/common/member_selector.dart';
import '../../widgets/common/paid_amounts_input.dart';
import '../../widgets/selectors/distribution_type_selector.dart';
import '../../widgets/common/manual_distribution_input.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/dialogs/expense/expense_receipt_section.dart';
import '../../utils/validators/expense_validator.dart';

class EditExpenseForm extends ConsumerStatefulWidget {
  final ExpenseModel expense;
  final GroupModel group;
  final VoidCallback onSuccess;

  const EditExpenseForm({super.key, required this.expense, required this.group, required this.onSuccess});

  @override
  ConsumerState<EditExpenseForm> createState() => _EditExpenseFormState();
}

class _EditExpenseFormState extends ConsumerState<EditExpenseForm> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  XFile? _receiptImage;

  String? _selectedCategoryId;
  DistributionType? _distributionType;
  List<String> _selectedMemberIds = [];
  Map<String, double> _manualAmounts = {};
  List<String> _payingMemberIds = [];
  Map<String, double> _paidAmounts = {};
  bool _imageRemoved = false;
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeForm();
  }

  void _initializeForm() {
    _amountController.text = widget.expense.amount.toStringAsFixed(2);
    _descriptionController.text = widget.expense.description;
    _selectedCategoryId = widget.expense.category;
    _selectedMemberIds = List.from(widget.expense.sharedBy);
    _imageRemoved = false;

    // Dağılım tipini belirle
    if (widget.expense.manualAmounts != null && widget.expense.manualAmounts!.isNotEmpty) {
      _distributionType = DistributionType.manual;
      _manualAmounts = Map.from(widget.expense.manualAmounts!);
    } else {
      _distributionType = DistributionType.equal;
    }

    // Ödeme bilgilerini belirle
    _paidAmounts = Map.from(widget.expense.payerAmounts);
    _payingMemberIds = _paidAmounts.keys.toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateExpense() async {
    // Açıklama kontrolü
    if (_descriptionController.text.trim().isEmpty) {
      _showWarningDialog('Lütfen masraf açıklaması giriniz.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

    // Validasyonlar
    final error = ExpenseValidator.validateForm(
      amount: amount,
      categoryId: _selectedCategoryId,
      selectedMemberIds: _selectedMemberIds,
      distributionType: _distributionType,
      manualAmounts: _manualAmounts,
    );

    if (error != null) {
      _showWarningDialog(error);
      return;
    }

    if (_payingMemberIds.isEmpty) {
      _showWarningDialog('Lütfen en az bir ödeyen kişi seçin');
      return;
    }

    // Manuel dağılım kontrolü
    if (_distributionType == DistributionType.manual) {
      final manualError = ExpenseValidator.validateManualDistribution(
        totalAmount: amount,
        manualAmounts: _manualAmounts,
      );
      if (manualError != null) {
        _showWarningDialog(manualError);
        return;
      }
    }

    // Ödeme tutarlarını kontrol et ve hazırla
    Map<String, double> finalPaidAmounts = {};
    if (_payingMemberIds.length == 1) {
      finalPaidAmounts[_payingMemberIds.first] = amount;
    } else {
      final filteredPaidAmounts = Map<String, double>.fromEntries(
        _paidAmounts.entries.where((e) => _payingMemberIds.contains(e.key) && e.value > 0),
      );
      final totalPaid = filteredPaidAmounts.values.fold(0.0, (sum, val) => sum + val);
      if (totalPaid == 0.0) {
        _showWarningDialog(
          'Birden fazla ödeyen seçtiniz. Lütfen "Ne Kadar" sekmesinden her ödeyenin ne kadar ödediğini giriniz.',
        );
        return;
      }
      if ((totalPaid - amount).abs() > 0.01) {
        _showWarningDialog(
          'Girilen ödeme tutarları toplamı (${totalPaid.toStringAsFixed(2)}) ana tutara (${amount.toStringAsFixed(2)}) eşit olmalıdır.',
        );
        return;
      }
      finalPaidAmounts = filteredPaidAmounts;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ErrorSnackBar.show(context, 'Giriş yapmanız gerekiyor');
      return;
    }

    // Sadece masrafı ekleyen kişi düzenleyebilir
    final canEdit = widget.expense.paidBy == currentUser.uid;
    if (!canEdit) {
      _showWarningDialog('Bu masrafı sadece masrafı ekleyen kişi düzenleyebilir');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Manuel dağılım varsa manualAmounts'ı gönder
      Map<String, double>? manualAmounts;
      if (_distributionType == DistributionType.manual && _manualAmounts.isNotEmpty) {
        manualAmounts = Map.from(_manualAmounts);
      }

      String? imageUrl = widget.expense.imageUrl;
      bool imageUpdated = _imageRemoved;

      if (_receiptImage != null) {
        final fileName = '${widget.expense.groupId}_${widget.expense.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageUrl = await FirebaseService.uploadFile(path: 'expense_receipts/$fileName', file: _receiptImage!);
        imageUpdated = true;
      } else if (_imageRemoved) {
        imageUrl = null;
      }

      await ref
          .read(expenseNotifierProvider.notifier)
          .updateExpense(
            expenseId: widget.expense.id,
            description: _descriptionController.text.trim(),
            amount: amount,
            category: _selectedCategoryId!,
            date: widget.expense.date,
            paidBy: _payingMemberIds.first,
            sharedBy: _selectedMemberIds,
            manualAmounts: manualAmounts,
            paidAmounts: finalPaidAmounts,
            imageUrl: imageUrl,
            imageUpdated: imageUpdated,
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
      } else if (widget.expense.imageUrl != null) {
        _imageRemoved = true;
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final canEdit = currentUser != null && widget.expense.paidBy == currentUser.uid;

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
            clearOnTap: canEdit,
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
            clearOnTap: canEdit,
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

          // Fotoğraf
          ExpenseReceiptSection(
            receiptImage: _receiptImage,
            imageUrl: _imageRemoved ? null : widget.expense.imageUrl,
            onPickImage: _pickReceiptImage,
            onRemoveImage: _removeReceiptImage,
            onShowPreview: _showImagePreview,
            canEdit: canEdit,
          ),
          const SizedBox(height: AppSpacing.textSpacing * 2),

          // Kategori
          IgnorePointer(
            ignoring: !canEdit,
            child: CategorySelector(
              selectedCategoryId: _selectedCategoryId,
              onCategorySelected: (categoryId) => setState(() => _selectedCategoryId = categoryId),
            ),
          ),
          const SizedBox(height: AppSpacing.sectionMargin),

          // Sekmeli Bölüm
          IgnorePointer(
            ignoring: !canEdit,
            child: DefaultTabController(
              length: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    tabs: const [Tab(text: 'Kimlere Ait'), Tab(text: 'Ödeme'), Tab(text: 'Ne Kadar')],
                  ),
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Kimlere Ait
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Masrafın kimlere ait olduğunu seçiniz',
                                style: AppTextStyles.label,
                                textAlign: TextAlign.left,
                              ),
                              const SizedBox(height: AppSpacing.textSpacing),
                              DistributionTypeSelector(
                                selectedType: _distributionType,
                                onTypeSelected: (type) => setState(() => _distributionType = type),
                              ),
                              const SizedBox(height: AppSpacing.textSpacing),
                              if (_distributionType == DistributionType.equal)
                                MemberSelector(
                                  selectedMemberIds: _selectedMemberIds,
                                  availableMemberIds: widget.group.memberIds,
                                  onMembersChanged: (memberIds) => setState(() => _selectedMemberIds = memberIds),
                                )
                              else
                                ManualDistributionInput(
                                  memberIds: widget.group.memberIds,
                                  totalAmount: double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0,
                                  manualAmounts: _manualAmounts,
                                  onChanged:
                                      (amounts) => setState(() {
                                        _manualAmounts = amounts;
                                        _selectedMemberIds = amounts.keys.where((k) => (amounts[k] ?? 0) > 0).toList();
                                      }),
                                ),
                            ],
                          ),
                        ),
                        // Tab 2: Ödeme
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ödemeyi kimin yaptığını seçiniz',
                                style: AppTextStyles.label,
                                textAlign: TextAlign.left,
                              ),
                              const SizedBox(height: AppSpacing.textSpacing),
                              MemberSelector(
                                selectedMemberIds: _payingMemberIds,
                                availableMemberIds: widget.group.memberIds,
                                onMembersChanged: (memberIds) => setState(() => _payingMemberIds = memberIds),
                              ),
                            ],
                          ),
                        ),
                        // Tab 3: Ne Kadar
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child:
                              _payingMemberIds.length > 1
                                  ? PaidAmountsInput(
                                    memberIds: _payingMemberIds,
                                    totalAmount: double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0,
                                    paidAmounts: _paidAmounts,
                                    onChanged: (amounts) => setState(() => _paidAmounts = amounts),
                                  )
                                  : Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(32),
                                      child: Text(
                                        _payingMemberIds.isEmpty
                                            ? 'Lütfen önce "Ödeme" sekmesinden ödeyen kişiyi seçiniz.'
                                            : 'Tek ödeyen seçildiğinde tüm tutar otomatik atanır.',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sectionMargin),

          // Güncelle Butonu
          CustomButton(
            text: 'Masrafı Güncelle',
            onPressed: (!canEdit || _isLoading) ? null : _updateExpense,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  void _showWarningDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
