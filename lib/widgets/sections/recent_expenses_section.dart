import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';
import '../../models/expense_model.dart';
import '../../models/expense_filter_model.dart';
import '../../models/user_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dialogs/delete_expense_dialog.dart';
import '../../controllers/expense_controller.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/common/async_value_builder.dart';
import '../../widgets/common/expenses_list.dart';
import '../../widgets/states/empty_expenses_state.dart';
import '../../widgets/common/loading_card.dart';
import '../../widgets/cards/error_card.dart';
import '../../widgets/dialogs/edit_expense_dialog.dart';
import '../../utils/expense_utils.dart';
import '../../utils/date_utils.dart' as app_date_utils;
import '../../constants/app_colors.dart';
import '../../constants/expense_categories.dart';
import '../../services/firebase_service.dart';
import '../recent_expenses/recent_expenses_filter_bottom_sheet.dart';
import '../recent_expenses/recent_expenses_filters_toolbar.dart';
import '../recent_expenses/recent_filter_chip.dart';

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
          RecentFilterChip(
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
        RecentFilterChip(
          label: label,
          icon: Icons.attach_money,
          color: AppColors.success,
          onRemove: _removeAmountFilter,
        ),
      );
    }

    if (_startDate != null || _endDate != null) {
      String label = '';
      if (_startDate != null && _endDate != null) {
        label =
            '${app_date_utils.AppDateUtils.formatDate(_startDate!)} - ${app_date_utils.AppDateUtils.formatDate(_endDate!)}';
      } else if (_startDate != null) {
        label = 'Başlangıç: ${app_date_utils.AppDateUtils.formatDate(_startDate!)}';
      } else {
        label = 'Bitiş: ${app_date_utils.AppDateUtils.formatDate(_endDate!)}';
      }
      chips.add(
        RecentFilterChip(label: label, icon: Icons.calendar_today, color: AppColors.info, onRemove: _removeDateFilter),
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
        RecentFilterChip(
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
        RecentExpensesFiltersToolbar(
          searchController: _searchController,
          onFilterTap: _showFilterBottomSheet,
          onClearFilters: _clearFilters,
          isFilterActive: _filter.isActive,
        ),
        // Aktif filtreler (varsa, ayrı satırda)
        if (activeFilters.isNotEmpty) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: activeFilters)),
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

            final currentUser = ref.watch(currentUserProvider);

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: ExpensesList(
                  expenses: displayExpenses,
                  onExpenseTap: (expense) {
                    if (expense.id.isNotEmpty) {
                      EditExpenseDialog.show(context, expense.id);
                    } else {
                      debugPrint('Expense ID boş: ${expense.id}');
                    }
                  },
                  onExpenseDelete: (expense) => _deleteExpense(expense),
                  showEditIcon: true,
                  showDeleteIcon: true,
                  groupMembers: _groupMembers,
                  currentUserId: currentUser?.uid,
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

  Future<void> _deleteExpense(ExpenseModel expense) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ErrorSnackBar.show(context, 'Giriş yapmanız gerekiyor');
      return;
    }

    final isPayer = expense.paidBy == currentUser.uid || (expense.paidAmounts?.containsKey(currentUser.uid) ?? false);
    if (!isPayer) {
      ErrorSnackBar.show(context, 'Bu masrafı sadece masrafı ekleyen kişi silebilir');
      return;
    }

    final confirmed = await DeleteExpenseDialog.show(
      context,
      expenseDescription: expense.description,
      expenseAmount: expense.amount,
    );

    if (confirmed != true) return;

    try {
      await ExpenseController.deleteExpense(ref, expense.id);

      if (mounted) {
        ErrorSnackBar.showSuccess(context, 'Masraf başarıyla silindi!');
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, e);
      }
    }
  }
}
