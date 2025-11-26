import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/expense_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/group_provider.dart';
import '../../widgets/common/async_value_builder.dart';
import '../../widgets/forms/edit_expense_form.dart';

/// Masraf düzenleme dialog'u
class EditExpenseDialog extends ConsumerStatefulWidget {
  final String expenseId;

  const EditExpenseDialog({super.key, required this.expenseId});

  static Future<void> show(BuildContext context, String expenseId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditExpenseDialog(expenseId: expenseId),
    );
  }

  @override
  ConsumerState<EditExpenseDialog> createState() => _EditExpenseDialogState();
}

class _EditExpenseDialogState extends ConsumerState<EditExpenseDialog> {
  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider(widget.expenseId));
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder:
            (context, scrollController) => AsyncValueBuilder<ExpenseModel?>(
              value: expenseState,
              dataBuilder: (context, expense) {
                if (expense == null) {
                  return const Center(child: Text('Masraf bulunamadı'));
                }

                final groupState = ref.watch(groupProvider(expense.groupId));
                return groupState.when(
                  data: (group) {
                    if (group == null) {
                      return const Center(child: Text('Grup bulunamadı'));
                    }

                    // Sadece masrafı ekleyen kişi düzenleyebilir
                    final canEdit = currentUser != null && expense.paidBy == currentUser.uid;

                    return Column(
                      children: [
                        // Handle bar
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Masraf Düzenle', style: AppTextStyles.h3.copyWith(color: theme.colorScheme.onSurface)),
                              IconButton(
                                icon: Icon(Icons.close, color: theme.colorScheme.onSurfaceVariant),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                        if (!canEdit)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Bu masrafı sadece masrafı ekleyen kişi düzenleyebilir. Bilgileri görüntüleyebilirsiniz.',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ),

                        // Form
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            padding: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                            ),
                            child: EditExpenseForm(
                              expense: expense,
                              group: group,
                              onSuccess: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Hata: $e')),
                );
              },
              loadingBuilder: (context) => const Center(child: CircularProgressIndicator()),
              errorBuilder: (context, error, stack) => Center(child: Text('Hata: $error')),
            ),
      ),
    );
  }
}
