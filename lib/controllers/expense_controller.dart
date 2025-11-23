import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/expense_provider.dart';
import '../services/firebase_service.dart';
import '../exceptions/middleware_exceptions.dart';

/// Expense Controller - MVC prensiplerine uygun masraf işlemleri controller'ı
class ExpenseController {
  /// Masraf silme işlemi
  /// Permission kontrolü ve diğer işlemler ExpenseNotifier içinde yapılıyor
  static Future<void> deleteExpense(
    WidgetRef ref,
    String expenseId,
  ) async {
    try {
      // Masrafın var olup olmadığını kontrol et
      final expenseDoc = await FirebaseService.getDocumentSnapshot('expenses/$expenseId');
      if (!expenseDoc.exists) {
        throw const NotFoundException('Masraf bulunamadı');
      }

      // ExpenseNotifier üzerinden silme işlemini gerçekleştir
      // (Permission kontrolü ve grup kontrolü provider'da yapılıyor)
      await ref.read(expenseNotifierProvider.notifier).deleteExpense(expenseId);
    } catch (e) {
      rethrow;
    }
  }
}

