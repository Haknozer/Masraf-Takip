import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/common/async_value_builder.dart';
import '../../widgets/common/expenses_list.dart';
import '../../widgets/states/empty_expenses_state.dart';
import '../../widgets/common/loading_card.dart';
import '../../widgets/cards/error_card.dart';
import '../../screens/expenses/edit_expense_page.dart';

class RecentExpensesSection extends ConsumerWidget {
  final String groupId;

  const RecentExpensesSection({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesState = ref.watch(groupExpensesProvider(groupId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Son Masraflar', style: AppTextStyles.h3),
        const SizedBox(height: 12),
        AsyncValueBuilder<List<ExpenseModel>>(
          value: expensesState,
          dataBuilder: (context, expenses) {
            // Son 5 masrafı göster, tarihe göre sırala (en yeni önce)
            final recentExpenses = expenses..sort((a, b) => b.date.compareTo(a.date));
            final displayExpenses = recentExpenses.take(5).toList();

            if (displayExpenses.isEmpty) {
              return const EmptyExpensesState();
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
