import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/expense_categories.dart';
import '../../models/user_model.dart';
import '../../utils/date_utils.dart' as date_utils;
import 'category_filter_chip.dart';

class RecentExpensesFilterBottomSheet extends StatefulWidget {
  final String? selectedCategoryId;
  final String minAmount;
  final String maxAmount;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? selectedUserId;
  final List<UserModel> groupMembers;
  final ValueChanged<String?> onCategorySelected;
  final void Function(String, String) onAmountChanged;
  final ValueChanged<DateTime?> onStartDateSelected;
  final ValueChanged<DateTime?> onEndDateSelected;
  final ValueChanged<String?> onUserSelected;

  const RecentExpensesFilterBottomSheet({
    super.key,
    required this.selectedCategoryId,
    required this.minAmount,
    required this.maxAmount,
    required this.startDate,
    required this.endDate,
    required this.selectedUserId,
    required this.groupMembers,
    required this.onCategorySelected,
    required this.onAmountChanged,
    required this.onStartDateSelected,
    required this.onEndDateSelected,
    required this.onUserSelected,
  });

  @override
  State<RecentExpensesFilterBottomSheet> createState() => _RecentExpensesFilterBottomSheetState();
}

class _RecentExpensesFilterBottomSheetState extends State<RecentExpensesFilterBottomSheet> {
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;
  String? _tempCategoryId;
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;
  String? _tempUserId;

  @override
  void initState() {
    super.initState();
    _minAmountController = TextEditingController(text: widget.minAmount);
    _maxAmountController = TextEditingController(text: widget.maxAmount);
    _tempCategoryId = widget.selectedCategoryId;
    _tempStartDate = widget.startDate;
    _tempEndDate = widget.endDate;
    _tempUserId = widget.selectedUserId;
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tempStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _tempStartDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tempEndDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _tempEndDate = picked);
    }
  }

  void _applyFilters() {
    widget.onCategorySelected(_tempCategoryId);
    widget.onAmountChanged(_minAmountController.text, _maxAmountController.text);
    widget.onStartDateSelected(_tempStartDate);
    widget.onEndDateSelected(_tempEndDate);
    widget.onUserSelected(_tempUserId);
    Navigator.pop(context);
  }

  void _resetTempFilters() {
    setState(() {
      _tempCategoryId = null;
      _tempStartDate = null;
      _tempEndDate = null;
      _tempUserId = null;
      _minAmountController.clear();
      _maxAmountController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.grey, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filtrele', style: AppTextStyles.h3),
                    TextButton(
                      onPressed: _resetTempFilters,
                      child: Text('Temizle', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Text('Kategori', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        CategoryFilterChip(
                          label: 'Tümü',
                          isSelected: _tempCategoryId == null,
                          onTap: () => setState(() => _tempCategoryId = null),
                        ),
                        ...ExpenseCategories.all.map(
                          (category) => CategoryFilterChip(
                            label: category.name,
                            icon: category.icon,
                            color: category.color,
                            isSelected: _tempCategoryId == category.id,
                            onTap: () => setState(() => _tempCategoryId = category.id),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Tutar Aralığı (₺)', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Min',
                              filled: true,
                              fillColor: AppColors.greyLight,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _maxAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Max',
                              filled: true,
                              fillColor: AppColors.greyLight,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Tarih Aralığı', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectStartDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.greyLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary),
                                  const SizedBox(width: 12),
                                  Text(
                                    _tempStartDate != null
                                        ? date_utils.AppDateUtils.formatDate(_tempStartDate!)
                                        : 'Başlangıç',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: _tempStartDate != null ? AppColors.textPrimary : AppColors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _selectEndDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.greyLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary),
                                  const SizedBox(width: 12),
                                  Text(
                                    _tempEndDate != null ? date_utils.AppDateUtils.formatDate(_tempEndDate!) : 'Bitiş',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: _tempEndDate != null ? AppColors.textPrimary : AppColors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Kişi', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _tempUserId,
                      decoration: InputDecoration(
                        hintText: 'Tümü',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: [
                        DropdownMenuItem<String>(value: null, child: Text('Tümü', style: AppTextStyles.bodyMedium)),
                        ...widget.groupMembers.map(
                          (member) => DropdownMenuItem<String>(
                            value: member.id,
                            child: Text(member.displayName, style: AppTextStyles.bodyMedium),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() => _tempUserId = value),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(color: AppColors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Uygula', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
