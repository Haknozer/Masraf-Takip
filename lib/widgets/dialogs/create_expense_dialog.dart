import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../models/group_model.dart';
import '../../widgets/forms/create_expense_form.dart';

/// Masraf ekleme dialog'u
class CreateExpenseDialog extends ConsumerStatefulWidget {
  final GroupModel group;

  const CreateExpenseDialog({super.key, required this.group});

  static Future<void> show(BuildContext context, GroupModel group) async {
    // Grup kapalıysa dialog açma, uyarı göster
    if (!group.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Grup kapalı. Yeni masraf eklenemez.'),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateExpenseDialog(group: group), fullscreenDialog: true),
    );
  }

  @override
  ConsumerState<CreateExpenseDialog> createState() => _CreateExpenseDialogState();
}

class _CreateExpenseDialogState extends ConsumerState<CreateExpenseDialog> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        title: const Text('Masraf Ekle'),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
          child: CreateExpenseForm(group: widget.group, onSuccess: () => Navigator.pop(context)),
        ),
      ),
    );
  }
}
