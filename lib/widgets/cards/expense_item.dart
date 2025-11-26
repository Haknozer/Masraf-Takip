import 'package:flutter/material.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/expense_categories.dart';
import '../../models/expense_model.dart';
import '../../models/user_model.dart';
import '../avatars/expense_item_avatar.dart';
import 'expense_item_subtitle.dart';
import 'expense_item_trailing.dart';

/// Masraf item widget'ı
class ExpenseItem extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showEditIcon;
  final bool showDeleteIcon;
  final List<UserModel>? groupMembers;
  final String? currentUserId;

  const ExpenseItem({
    super.key,
    required this.expense,
    this.onTap,
    this.onDelete,
    this.showEditIcon = false,
    this.showDeleteIcon = false,
    this.groupMembers,
    this.currentUserId,
  });

  String _getUserName(String userId) {
    if (groupMembers == null) return 'Bilinmeyen';
    final user = groupMembers!.firstWhere(
      (u) => u.id == userId,
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
    return user.displayName;
  }

  String _buildPayerInfo() {
    final payerMap = expense.paidAmounts;
    if (payerMap == null || payerMap.isEmpty) {
      final name = _getUserName(expense.paidBy);
      return '$name ödedi';
    }
    final sorted = payerMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final firstName = _getUserName(sorted.first.key);
    if (sorted.length == 1) {
      return '$firstName ${sorted.first.value.toStringAsFixed(2)} ₺ ödedi';
    }
    final others = sorted.length - 1;
    return '$firstName +$others kişi ödedi';
  }

  bool _canCurrentUserDelete() {
    if (currentUserId == null) return false;
    if (expense.paidBy == currentUserId) return true;
    if (expense.paidAmounts != null && expense.paidAmounts!.containsKey(currentUserId)) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final category = ExpenseCategories.getById(expense.category);
    final icon = category?.icon ?? Icons.receipt;
    final color = category?.color ?? Theme.of(context).colorScheme.primary;
    final participantCount = expense.sharedBy.length;
    final payerInfo = _buildPayerInfo();
    final canDelete = _canCurrentUserDelete();

    final content = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            ExpenseItemAvatar(imageUrl: expense.imageUrl, icon: icon, color: color),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.description,
                    style: AppTextStyles.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  ExpenseItemSubtitle(
                    date: expense.date,
                    payerInfo: payerInfo,
                    participantCount: participantCount,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Trailing
            ExpenseItemTrailing(
              amount: expense.amount,
              showEditIcon: showEditIcon,
              showDeleteIcon: false, // Artık buton olarak göstermeyelim
              canDelete: canDelete,
              onTap: onTap,
              onDelete: onDelete,
            ),
          ],
        ),
      ),
    );

    // Eğer silme özelliği varsa ve kullanıcı silebiliyorsa, Dismissible ile sarmalayalım
    if (showDeleteIcon && canDelete && onDelete != null) {
      return Dismissible(
        key: Key(expense.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: Theme.of(context).colorScheme.error,
          child: const Icon(Icons.delete, color: Colors.white, size: 28),
        ),
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Masrafı Sil')),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${expense.description} masrafını silmek istediğinizden emin misiniz?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tutar:',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${expense.amount.toStringAsFixed(2)} ₺',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Theme.of(context).colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bu işlem geri alınamaz',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'İptal',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Sil'),
                ),
              ],
            ),
          );
        },
        onDismissed: (direction) => onDelete!(),
        child: content,
      );
    }

    return content;
  }
}
