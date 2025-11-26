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
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditExpenseDialog(expenseId: expenseId),
        fullscreenDialog: true,
      ),
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

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        title: const Text('Masraf Düzenle'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: AsyncValueBuilder<ExpenseModel?>(
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
                    if (!canEdit)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Bu masrafı sadece masrafı ekleyen kişi düzenleyebilir. Bilgileri görüntüleyebilirsiniz.',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: canEdit ? 16 : 0,
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
