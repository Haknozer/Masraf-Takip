import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
import '../models/group_model.dart';
import '../services/firebase_service.dart';
import '../middleware/auth_middleware.dart';
import '../middleware/permission_middleware.dart';
import '../exceptions/middleware_exceptions.dart';
import 'auth_provider.dart';

// Group Expenses Provider
final groupExpensesProvider = StreamProvider.family<List<ExpenseModel>, String>((ref, groupId) {
  return FirebaseService.listenToCollection('expenses').map(
    (snapshot) =>
        snapshot.docs
            .where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['groupId'] == groupId;
            })
            .map((doc) => ExpenseModel.fromJson({'id': doc.id, ...doc.data() as Map<String, dynamic>}))
            .toList(),
  );
});

// Expense Notifier
class ExpenseNotifier extends StateNotifier<AsyncValue<List<ExpenseModel>>> {
  ExpenseNotifier(this.ref) : super(const AsyncValue.loading());

  final Ref ref;

  void loadExpenses(String groupId) {
    FirebaseService.listenToCollection('expenses').listen((snapshot) {
      final expenses =
          snapshot.docs
              .where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['groupId'] == groupId;
              })
              .map((doc) => ExpenseModel.fromJson({'id': doc.id, ...doc.data() as Map<String, dynamic>}))
              .toList();
      state = AsyncValue.data(expenses);
    });
  }

  // Masraf ekle
  Future<void> addExpense({
    required String groupId,
    required String paidBy,
    required String description,
    required double amount,
    required String category,
    required DateTime date,
    required List<String> sharedBy,
    String? imageUrl,
  }) async {
    final user = ref.read(currentUserProvider);

    // Middleware: Authentication kontrolü
    AuthMiddleware.requireAuth(user);

    try {
      // Grup bilgisini al
      final groupDoc = await FirebaseService.getDocumentSnapshot('groups/$groupId');
      if (!groupDoc.exists) {
        throw const NotFoundException('Grup bulunamadı');
      }

      final group = GroupModel.fromJson({'id': groupDoc.id, ...groupDoc.data() as Map<String, dynamic>});

      // Middleware: Permission kontrolü
      PermissionMiddleware.requireCanAddExpense(user, group);

      final expense = ExpenseModel(
        id: '', // Firebase otomatik ID verecek
        groupId: groupId,
        paidBy: paidBy,
        description: description,
        amount: amount,
        category: category,
        date: date,
        sharedBy: sharedBy,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirebaseService.addDocument(collection: 'expenses', data: expense.toJson());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Masraf güncelle
  Future<void> updateExpense({
    required String expenseId,
    required String description,
    required double amount,
    required String category,
    required DateTime date,
    required List<String> sharedBy,
    String? imageUrl,
  }) async {
    final user = ref.read(currentUserProvider);

    // Middleware: Authentication kontrolü
    AuthMiddleware.requireAuth(user);

    try {
      // Masraf bilgisini al
      final expenseDoc = await FirebaseService.getDocumentSnapshot('expenses/$expenseId');
      if (!expenseDoc.exists) {
        throw const NotFoundException('Masraf bulunamadı');
      }

      final expense = ExpenseModel.fromJson({'id': expenseDoc.id, ...expenseDoc.data() as Map<String, dynamic>});

      // Grup bilgisini al
      final groupDoc = await FirebaseService.getDocumentSnapshot('groups/${expense.groupId}');
      if (!groupDoc.exists) {
        throw const NotFoundException('Grup bulunamadı');
      }

      final group = GroupModel.fromJson({'id': groupDoc.id, ...groupDoc.data() as Map<String, dynamic>});

      // Middleware: Permission kontrolü
      PermissionMiddleware.requireCanEditExpense(user, group, expense);

      await FirebaseService.updateDocument(
        path: 'expenses/$expenseId',
        data: {
          'description': description,
          'amount': amount,
          'category': category,
          'date': date.toIso8601String(),
          'sharedBy': sharedBy,
          'imageUrl': imageUrl,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Masraf sil
  Future<void> deleteExpense(String expenseId) async {
    final user = ref.read(currentUserProvider);

    // Middleware: Authentication kontrolü
    AuthMiddleware.requireAuth(user);

    try {
      // Masraf bilgisini al
      final expenseDoc = await FirebaseService.getDocumentSnapshot('expenses/$expenseId');
      if (!expenseDoc.exists) {
        throw const NotFoundException('Masraf bulunamadı');
      }

      final expense = ExpenseModel.fromJson({'id': expenseDoc.id, ...expenseDoc.data() as Map<String, dynamic>});

      // Grup bilgisini al
      final groupDoc = await FirebaseService.getDocumentSnapshot('groups/${expense.groupId}');
      if (!groupDoc.exists) {
        throw const NotFoundException('Grup bulunamadı');
      }

      final group = GroupModel.fromJson({'id': groupDoc.id, ...groupDoc.data() as Map<String, dynamic>});

      // Middleware: Permission kontrolü
      PermissionMiddleware.requireCanDeleteExpense(user, group, expense);

      await FirebaseService.deleteDocument('expenses/$expenseId');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Kategoriye göre masrafları filtrele
  List<ExpenseModel> getExpensesByCategory(String category) {
    return state.when(
      data: (expenses) => expenses.where((e) => e.category == category).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }

  // Tarihe göre masrafları filtrele
  List<ExpenseModel> getExpensesByDateRange(DateTime startDate, DateTime endDate) {
    return state.when(
      data: (expenses) => expenses.where((e) => e.date.isAfter(startDate) && e.date.isBefore(endDate)).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }

  // Toplam masraf hesapla
  double getTotalExpenses() {
    return state.when(
      data: (expenses) => expenses.fold(0.0, (sum, expense) => sum + expense.amount),
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );
  }

  // Kullanıcı başına düşen masraf hesapla
  double getUserExpense(String userId) {
    return state.when(
      data: (expenses) {
        double total = 0.0;
        for (final expense in expenses) {
          if (expense.sharedBy.contains(userId)) {
            total += expense.amountPerPerson;
          }
        }
        return total;
      },
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );
  }
}

// Expense Notifier Provider
final expenseNotifierProvider = StateNotifierProvider<ExpenseNotifier, AsyncValue<List<ExpenseModel>>>((ref) {
  return ExpenseNotifier(ref);
});
