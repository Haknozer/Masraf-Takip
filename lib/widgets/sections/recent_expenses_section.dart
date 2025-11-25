import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';
import '../../models/expense_model.dart';
import '../../models/expense_filter_model.dart';
import '../../models/user_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/group_provider.dart';
import '../../widgets/common/async_value_builder.dart';
import '../../widgets/common/expenses_list.dart';
import '../../widgets/states/empty_expenses_state.dart';
import '../../widgets/common/loading_card.dart';
import '../../widgets/cards/error_card.dart';
import '../../screens/expenses/edit_expense_page.dart';
import '../../utils/expense_utils.dart';
import '../../utils/date_utils.dart' as DateUtils;
import '../../constants/app_colors.dart';
import '../../constants/expense_categories.dart';
import '../../services/firebase_service.dart';
import '../recent_expenses/recent_expenses_filter_bottom_sheet.dart';

class RecentExpensesSection extends ConsumerStatefulWidget {
  final String groupId;

  const RecentExpensesSection({super.key, required this.groupId});

  @override
  ConsumerState<RecentExpensesSection> createState() => _RecentExpensesSectionState();
}

class _RecentExpensesSectionState extends ConsumerState<RecentExpensesSection> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  ExpenseFilter _filter = const ExpenseFilter();
  String? _selectedCategoryId;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedUserId;
  List<UserModel> _groupMembers = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_updateFilter);
    _minAmountController.addListener(_updateFilter);
    _maxAmountController.addListener(_updateFilter);
    _loadGroupMembers();
  }

  Future<void> _loadGroupMembers() async {
    final groupState = ref.read(groupProvider(widget.groupId));
    groupState.whenData((group) async {
      if (group != null) {
        final members = <UserModel>[];
        for (final memberId in group.memberIds) {
          try {
            final userDoc = await FirebaseService.getDocumentSnapshot('users/$memberId');
            if (userDoc.exists) {
              final data = userDoc.data() as Map<String, dynamic>;
              members.add(UserModel.fromJson(data));
            }
          } catch (e) {
            // Hata durumunda devam et
          }
        }
        if (mounted) {
          setState(() {
            _groupMembers = members;
          });
        }
      }
    });
  }

  void _updateFilter() {
    setState(() {
      final minAmount =
          _minAmountController.text.trim().isEmpty
              ? null
              : double.tryParse(_minAmountController.text.replaceAll(',', '.'));
      final maxAmount =
          _maxAmountController.text.trim().isEmpty
              ? null
              : double.tryParse(_maxAmountController.text.replaceAll(',', '.'));

      _filter = ExpenseFilter(
        searchQuery: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        categoryId: _selectedCategoryId,
        minAmount: minAmount,
        maxAmount: maxAmount,
        startDate: _startDate,
        endDate: _endDate,
        userId: _selectedUserId,
      );
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _minAmountController.clear();
      _maxAmountController.clear();
      _selectedCategoryId = null;
      _startDate = null;
      _endDate = null;
      _selectedUserId = null;
      _filter = const ExpenseFilter();
    });
  }

  void _removeCategoryFilter() {
    setState(() {
      _selectedCategoryId = null;
      _updateFilter();
    });
  }

  void _removeAmountFilter() {
    setState(() {
      _minAmountController.clear();
      _maxAmountController.clear();
      _updateFilter();
    });
  }

  void _removeDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _updateFilter();
    });
  }

  void _removeUserFilter() {
    setState(() {
      _selectedUserId = null;
      _updateFilter();
    });
  }

  Future<void> _showFilterBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder:
          (context) => RecentExpensesFilterBottomSheet(
            selectedCategoryId: _selectedCategoryId,
            minAmount: _minAmountController.text,
            maxAmount: _maxAmountController.text,
            startDate: _startDate,
            endDate: _endDate,
            selectedUserId: _selectedUserId,
            groupMembers: _groupMembers,
            onCategorySelected: (categoryId) {
              setState(() {
                _selectedCategoryId = categoryId;
                _updateFilter();
              });
            },
            onAmountChanged: (min, max) {
              setState(() {
                _minAmountController.text = min;
                _maxAmountController.text = max;
                _updateFilter();
              });
            },
            onStartDateSelected: (date) {
              setState(() {
                _startDate = date;
                _updateFilter();
              });
            },
            onEndDateSelected: (date) {
              setState(() {
                _endDate = date;
                _updateFilter();
              });
            },
            onUserSelected: (userId) {
              setState(() {
                _selectedUserId = userId;
                _updateFilter();
              });
            },
          ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  List<Widget> _buildActiveFilterChips() {
    final chips = <Widget>[];

    if (_selectedCategoryId != null) {
      final category = ExpenseCategories.getById(_selectedCategoryId!);
      if (category != null) {
        chips.add(
          _FilterChip(
            label: category.name,
            icon: category.icon,
            color: category.color,
            onRemove: _removeCategoryFilter,
          ),
        );
      }
    }

    if (_minAmountController.text.isNotEmpty || _maxAmountController.text.isNotEmpty) {
      String label = '';
      if (_minAmountController.text.isNotEmpty && _maxAmountController.text.isNotEmpty) {
        label = '${_minAmountController.text} - ${_maxAmountController.text} ₺';
      } else if (_minAmountController.text.isNotEmpty) {
        label = 'Min: ${_minAmountController.text} ₺';
      } else {
        label = 'Max: ${_maxAmountController.text} ₺';
      }
      chips.add(
        _FilterChip(label: label, icon: Icons.attach_money, color: AppColors.success, onRemove: _removeAmountFilter),
      );
    }

    if (_startDate != null || _endDate != null) {
      String label = '';
      if (_startDate != null && _endDate != null) {
        label = '${DateUtils.AppDateUtils.formatDate(_startDate!)} - ${DateUtils.AppDateUtils.formatDate(_endDate!)}';
      } else if (_startDate != null) {
        label = 'Başlangıç: ${DateUtils.AppDateUtils.formatDate(_startDate!)}';
      } else {
        label = 'Bitiş: ${DateUtils.AppDateUtils.formatDate(_endDate!)}';
      }
      chips.add(
        _FilterChip(label: label, icon: Icons.calendar_today, color: AppColors.info, onRemove: _removeDateFilter),
      );
    }

    if (_selectedUserId != null) {
      final member = _groupMembers.firstWhere(
        (m) => m.id == _selectedUserId,
        orElse:
            () => UserModel(
              id: '',
              email: '',
              displayName: 'Bilinmeyen',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              groups: [],
            ),
      );
      chips.add(
        _FilterChip(
          label: member.displayName,
          icon: Icons.person,
          color: AppColors.accent,
          onRemove: _removeUserFilter,
        ),
      );
    }

    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final expensesState = ref.watch(groupExpensesProvider(widget.groupId));
    final activeFilters = _buildActiveFilterChips();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Son Masraflar', style: AppTextStyles.h3),
        const SizedBox(height: 12),
        // Arama ve Filtreleme yan yana
        Row(
          children: [
            // Arama bar (küçültülmüş)
            Expanded(
              flex: 3,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchController,
                    builder: (context, value, child) {
                      return TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Masraf ara...',
                          hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
                          prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                          suffixIcon: value.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                                  onPressed: _searchController.clear,
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.greyLight, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.greyLight, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        style: AppTextStyles.bodySmall,
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Filtreleme butonu
            OutlinedButton.icon(
              onPressed: _showFilterBottomSheet,
              icon: Icon(
                Icons.filter_list,
                size: 18,
                color: _filter.isActive ? AppColors.primary : AppColors.textSecondary,
              ),
              label: Text(
                'Filtrele',
                style: AppTextStyles.bodySmall.copyWith(
                  color: _filter.isActive ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                side: BorderSide(
                  color: _filter.isActive ? AppColors.primary : AppColors.grey,
                  width: _filter.isActive ? 1.5 : 1,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: _filter.isActive ? AppColors.primary.withOpacity(0.1) : null,
              ),
            ),
            if (_filter.isActive)
              IconButton(
                icon: Icon(Icons.clear_all, size: 20, color: AppColors.error),
                onPressed: _clearFilters,
                tooltip: 'Tüm filtreleri temizle',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        // Aktif filtreler (varsa, ayrı satırda)
        if (activeFilters.isNotEmpty) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: activeFilters,
            ),
          ),
        ],
        const SizedBox(height: 12),
        AsyncValueBuilder<List<ExpenseModel>>(
          value: expensesState,
          dataBuilder: (context, expenses) {
            // Tarihe göre sırala (en yeni önce)
            final sortedExpenses = List<ExpenseModel>.from(expenses)..sort((a, b) => b.date.compareTo(a.date));

            // Filtreleme uygula
            List<ExpenseModel> displayExpenses;
            if (_filter.isActive) {
              displayExpenses = ExpenseUtils.filterExpensesAdvanced(sortedExpenses, _filter);
            } else {
              displayExpenses = sortedExpenses.take(5).toList();
            }

            if (displayExpenses.isEmpty) {
              return EmptyExpensesState(
                message: _filter.isActive ? 'Filtreleme sonucu bulunamadı' : 'Henüz masraf eklenmemiş',
              );
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: ExpensesList(
                  expenses: displayExpenses,
                  onExpenseTap: (expense) {
                    if (expense.id.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditExpensePage(expenseId: expense.id)),
                      ).then((_) {
                        // Sayfa geri döndüğünde refresh yapılabilir
                      });
                    } else {
                      debugPrint('Expense ID boş: ${expense.id}');
                    }
                  },
                  showEditIcon: true,
                  groupMembers: _groupMembers,
                ),
              ),
            );
          },
          loadingBuilder: (context) => const LoadingCard(),
          errorBuilder: (context, error, stack) => const ErrorCard(error: 'Masraflar yüklenemedi'),
        ),
      ],
    );
  }
}

// Filtre chip widget'ı
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, required this.icon, required this.color, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              Icon(Icons.close, size: 14, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

// Filtre bottom sheet widget'ı
class _FilterBottomSheet extends StatefulWidget {
  final String? selectedCategoryId;
  final String minAmount;
  final String maxAmount;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? selectedUserId;
  final List<UserModel> groupMembers;
  final Function(String?) onCategorySelected;
  final Function(String, String) onAmountChanged;
  final Function(DateTime?) onStartDateSelected;
  final Function(DateTime?) onEndDateSelected;
  final Function(String?) onUserSelected;

  const _FilterBottomSheet({
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
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
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
      setState(() {
        _tempStartDate = picked;
      });
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
      setState(() {
        _tempEndDate = picked;
      });
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

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder:
          (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                        onPressed: () {
                          setState(() {
                            _tempCategoryId = null;
                            _tempStartDate = null;
                            _tempEndDate = null;
                            _tempUserId = null;
                            _minAmountController.clear();
                            _maxAmountController.clear();
                          });
                        },
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
                      // Kategori
                      Text('Kategori', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _CategoryChip(
                            label: 'Tümü',
                            isSelected: _tempCategoryId == null,
                            onTap: () => setState(() => _tempCategoryId = null),
                          ),
                          ...ExpenseCategories.all.map((category) {
                            return _CategoryChip(
                              label: category.name,
                              icon: category.icon,
                              color: category.color,
                              isSelected: _tempCategoryId == category.id,
                              onTap: () => setState(() => _tempCategoryId = category.id),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Tutar
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
                      // Tarih
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
                                          ? DateUtils.AppDateUtils.formatDate(_tempStartDate!)
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
                                      _tempEndDate != null ? DateUtils.AppDateUtils.formatDate(_tempEndDate!) : 'Bitiş',
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
                      // Kişi
                      Text('Kişi', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _tempUserId,
                        decoration: InputDecoration(
                          hintText: 'Tümü',
                          filled: true,
                          fillColor: AppColors.greyLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: [
                          DropdownMenuItem<String>(value: null, child: Text('Tümü', style: AppTextStyles.bodyMedium)),
                          ...widget.groupMembers.map((member) {
                            return DropdownMenuItem<String>(
                              value: member.id,
                              child: Text(member.displayName, style: AppTextStyles.bodyMedium),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _tempUserId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                // Uygula butonu
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
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
          ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, this.icon, this.color, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withOpacity(0.15) : AppColors.greyLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? chipColor : AppColors.greyLight, width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: isSelected ? chipColor : AppColors.textSecondary),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? chipColor : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
