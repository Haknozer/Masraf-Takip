import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_spacing.dart';
import '../../models/expense_model.dart';
import '../../models/group_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/forms/custom_text_field.dart';
import '../../widgets/forms/custom_button.dart';
import '../../widgets/common/category_selector.dart';
import '../../widgets/selectors/distribution_type_selector.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/dialogs/expense/expense_receipt_section.dart';
import '../../utils/validators/expense_validator.dart';
import 'sections/expense_distribution_section.dart';

class EditExpenseForm extends ConsumerStatefulWidget {
  final ExpenseModel expense;
  final GroupModel group;
  final VoidCallback onSuccess;

  const EditExpenseForm({super.key, required this.expense, required this.group, required this.onSuccess});

  @override
  ConsumerState<EditExpenseForm> createState() => _EditExpenseFormState();
}

class _EditExpenseFormState extends ConsumerState<EditExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  XFile? _receiptImage;

  String? _selectedCategoryId;
  DistributionType? _distributionType;
  List<String> _selectedMemberIds = [];
  Map<String, double> _manualAmounts = {};
  bool _imageRemoved = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateExpense() async {
    if (!_formKey.currentState!.validate()) return;

    // Validasyonlar
    final error = ExpenseValidator.validateForm(
      amount: double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0,
      categoryId: _selectedCategoryId,
      selectedMemberIds: _selectedMemberIds,
      distributionType: _distributionType,
      manualAmounts: _manualAmounts,
    );

    if (error != null) {
      ErrorSnackBar.showWarning(context, error);
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ErrorSnackBar.show(context, 'Giriş yapmanız gerekiyor');
      return;
    }

    // Sadece masrafı ekleyen kişi düzenleyebilir
    // Not: Bu kontrol zaten dialogda yapılıyor ama güvenlik için burada da kalabilir
    final canEdit = widget.expense.paidBy == currentUser.uid;
    if (!canEdit) {
      ErrorSnackBar.show(context, 'Bu masrafı sadece masrafı ekleyen kişi düzenleyebilir');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

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
            date: widget.expense.date, // Tarih değiştirilemez
            paidBy: widget.expense.paidBy, // Ödeyen kişi değiştirilemez
            sharedBy: _selectedMemberIds,
            manualAmounts: manualAmounts,
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

          // Dağılım Bölümü
          IgnorePointer(
            ignoring: !canEdit,
            child: ExpenseDistributionSection(
              selectedMemberIds: _selectedMemberIds,
              availableMemberIds: widget.group.memberIds,
              onMembersChanged: (memberIds) => setState(() => _selectedMemberIds = memberIds),
              distributionType: _distributionType,
              onDistributionTypeChanged: (type) => setState(() => _distributionType = type),
              manualAmounts: _manualAmounts,
              onManualAmountsChanged: (amounts) => setState(() => _manualAmounts = amounts),
              totalAmount: double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0,
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
}
