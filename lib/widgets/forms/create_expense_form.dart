import 'package:expense_tracker_app/utils/date_utils.dart' as app_date_utils;
import 'package:expense_tracker_app/widgets/common/category_selector.dart';
import 'package:expense_tracker_app/widgets/common/member_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';
import '../../models/group_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/forms/custom_text_field.dart';
import '../../widgets/forms/custom_button.dart';
import '../../widgets/selectors/distribution_type_selector.dart';
import '../../widgets/common/manual_distribution_input.dart';
import '../../widgets/common/paid_amounts_input.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/dialogs/expense/expense_receipt_section.dart';
import '../../utils/validators/expense_validator.dart';

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

  // Tab State
  List<String> _selectedMemberIds = []; // Kimlere Ait (SharedBy)
  List<String> _payingMemberIds = []; // Kimler Ödedi (Payers)
  Map<String, double> _paidAmounts = {}; // Ne Kadar Ödedi (Amounts)

  // Distribution State
  DistributionType _distributionType = DistributionType.equal;
  Map<String, double> _manualAmounts = {}; // Manuel dağılım için (Kimlere Ait sekmesi için)

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(currentUserProvider);
    // Varsayılan olarak tüm grup üyeleri seçili olsun
    _selectedMemberIds = List.from(widget.group.memberIds);

    // Varsayılan olarak mevcut kullanıcıyı ödeyen olarak seç (Kimler Ödedi)
    if (currentUser != null) {
      _payingMemberIds = [currentUser.uid];
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

    // Açıklama kontrolü
    if (_descriptionController.text.trim().isEmpty) {
      _showWarningDialog('Lütfen masraf açıklaması giriniz.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

    // Temel validasyonlar (Validator sınıfı kullanılarak)
    // Not: Artık sadece amount ve category kullanıcı tarafından giriliyor, diğerleri otomatik.
    // Bu yüzden ExpenseValidator.validateForm'u basitleştirilmiş parametrelerle çağıracağız veya manuel kontrol edeceğiz.

    // Özel Validasyonlar
    if (_selectedCategoryId == null) {
      _showWarningDialog('Lütfen bir kategori seçin');
      return;
    }

    if (amount <= 0) {
      _showWarningDialog('Tutar 0\'dan büyük olmalıdır');
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ErrorSnackBar.show(context, 'Giriş yapmanız gerekiyor');
      return;
    }

    // Otomatik değerler:
    // Ödeyenler: _payingMemberIds
    // Paylaşılanlar: _selectedMemberIds

    if (_payingMemberIds.isEmpty) {
      _showWarningDialog('Lütfen en az bir ödeyen kişi seçin');
      return;
    }

    if (_selectedMemberIds.isEmpty) {
      _showWarningDialog('Lütfen masrafın kime ait olduğunu seçiniz');
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
      // Tek ödeyen varsa tüm tutarı ona yaz
      finalPaidAmounts[_payingMemberIds.first] = amount;
    } else {
      // Çoklu ödeyen varsa girilen tutarları kontrol et
      // _paidAmounts map'ini _payingMemberIds ile filtrele
      final filteredPaidAmounts = Map<String, double>.fromEntries(
        _paidAmounts.entries.where((e) => _payingMemberIds.contains(e.key) && e.value > 0),
      );

      final totalPaid = filteredPaidAmounts.values.fold(0.0, (sum, val) => sum + val);

      // Hiç tutar girilmemiş mi kontrol et
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

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_receiptImage != null) {
        final fileName = '${widget.group.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageUrl = await FirebaseService.uploadFile(path: 'expense_receipts/$fileName', file: _receiptImage!);
      }

      await ref
          .read(expenseNotifierProvider.notifier)
          .addExpense(
            groupId: widget.group.id,
            paidBy:
                _payingMemberIds
                    .first, // Ana ödeyen (ilk kişi) - Backend çoklu ödeme destekliyorsa paidAmounts kullanılır
            description: _descriptionController.text.trim(),
            amount: amount,
            category: _selectedCategoryId!,
            date: _selectedDate,
            sharedBy: _selectedMemberIds,
            manualAmounts: _distributionType == DistributionType.manual ? _manualAmounts : null,
            paidAmounts: finalPaidAmounts,
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
    // final totalAmount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
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
            clearOnTap: true,
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
            clearOnTap: true,
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
          const SizedBox(height: AppSpacing.sectionMargin),

          // Tabs Section
          DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  tabs: const [Tab(text: 'Kimlere Ait'), Tab(text: 'Ödeme'), Tab(text: 'Ne Kadar')],
                ),
                const SizedBox(height: AppSpacing.textSpacing),
                SizedBox(
                  height: 300, // Fixed height for tab content
                  child: TabBarView(
                    children: [
                      // Tab 1: Masraf Kimlere Ait (SharedBy)
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Text(
                                'Masrafın kimlere ait olduğunu seçiniz',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Dağılım Tipi Seçici
                            DistributionTypeSelector(
                              selectedType: _distributionType,
                              onTypeSelected: (type) => setState(() => _distributionType = type),
                            ),
                            const SizedBox(height: 16),

                            if (_distributionType == DistributionType.equal)
                              MemberSelector(
                                selectedMemberIds: _selectedMemberIds,
                                onMembersChanged: (ids) => setState(() => _selectedMemberIds = ids),
                                availableMemberIds: widget.group.memberIds,
                              )
                            else
                              ManualDistributionInput(
                                memberIds: widget.group.memberIds,
                                totalAmount: double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0,
                                manualAmounts: _manualAmounts,
                                onChanged: (amounts) {
                                  setState(() {
                                    _manualAmounts = amounts;
                                    // Tutarı > 0 olanları seçili üye yap
                                    _selectedMemberIds =
                                        amounts.entries.where((e) => e.value > 0).map((e) => e.key).toList();
                                  });
                                },
                              ),
                          ],
                        ),
                      ),

                      // Tab 2: Ödeme (Payers)
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Text(
                                'Ödemeyi kimin yaptığını seçiniz',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                            const SizedBox(height: 16),
                            MemberSelector(
                              selectedMemberIds: _payingMemberIds,
                              onMembersChanged: (ids) {
                                setState(() {
                                  _payingMemberIds = ids;
                                  // Eğer tek kişi seçildiyse, tüm tutarı ona ata (otomatik)
                                  if (ids.length == 1) {
                                    final total = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
                                    _paidAmounts = {ids.first: total};
                                  }
                                });
                              },
                              availableMemberIds: widget.group.memberIds,
                            ),
                          ],
                        ),
                      ),

                      // Tab 3: Ne Kadar Ödedi (Amounts)
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            if (_payingMemberIds.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    'Lütfen önce "Kimler Ödedi" sekmesinden ödeyen kişileri seçin.',
                                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            else if (_payingMemberIds.length == 1)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    'Tek kişi ödediği için tutar otomatik olarak ayarlandı.',
                                    style: AppTextStyles.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            else
                              PaidAmountsInput(
                                memberIds: _payingMemberIds,
                                totalAmount: double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0,
                                paidAmounts: _paidAmounts,
                                onChanged: (amounts) => setState(() => _paidAmounts = amounts),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sectionMargin),

          // Masraf Ekle Butonu
          CustomButton(text: 'Masraf Ekle', onPressed: _isLoading ? null : _createExpense, isLoading: _isLoading),
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
