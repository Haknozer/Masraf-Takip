import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';
import '../models/expense_filter_model.dart';
import '../constants/expense_categories.dart';

/// Expense ile ilgili yardımcı fonksiyonlar
class ExpenseUtils {
  /// Firebase DocumentSnapshot'dan ExpenseModel oluştur
  /// Document ID'sini data içindeki id'den öncelikli olarak kullanır
  static ExpenseModel? fromDocumentSnapshot(DocumentSnapshot doc) {
    if (!doc.exists) return null;

    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return null;

      // Firebase document ID'sini kullan, data içindeki id'yi override et
      data['id'] = doc.id;
      return ExpenseModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// QueryDocumentSnapshot listesinden ExpenseModel listesi oluştur
  static List<ExpenseModel> fromQuerySnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      // Firebase document ID'sini kullan, data içindeki id'yi override et
      data['id'] = doc.id;
      return ExpenseModel.fromJson(data);
    }).toList();
  }

  /// ExpenseId validasyonu
  /// Geçerli bir expense ID olup olmadığını kontrol eder
  static bool isValidExpenseId(String expenseId) {
    if (expenseId.isEmpty || expenseId.trim().isEmpty) {
      return false;
    }

    final trimmedId = expenseId.trim();
    // Firebase path'lerinde geçersiz karakterler olmamalı
    if (trimmedId.contains('/') || trimmedId.contains('\\') || trimmedId.contains('..')) {
      return false;
    }

    return true;
  }

  /// ExpenseId'yi temizle ve validate et
  /// Geçersizse null döndürür
  static String? sanitizeExpenseId(String expenseId) {
    if (!isValidExpenseId(expenseId)) {
      return null;
    }
    return expenseId.trim();
  }

  /// Masrafları arama terimine göre filtrele
  /// Description, kategori adı ve tutar alanlarında arama yapar
  static List<ExpenseModel> filterExpenses(List<ExpenseModel> expenses, String searchQuery) {
    if (searchQuery.trim().isEmpty) {
      return expenses;
    }

    final query = searchQuery.toLowerCase().trim();

    return expenses.where((expense) {
      // Açıklamada ara
      if (expense.description.toLowerCase().contains(query)) {
        return true;
      }

      // Kategori adında ara
      final category = ExpenseCategories.getById(expense.category);
      if (category != null && category.name.toLowerCase().contains(query)) {
        return true;
      }

      // Tutarda ara (sayısal değer olarak)
      try {
        final amount = double.parse(query);
        if (expense.amount == amount || expense.amount.toString().contains(query)) {
          return true;
        }
      } catch (e) {
        // Sayısal değer değilse, tutar string'inde ara
        if (expense.amount.toString().contains(query)) {
          return true;
        }
      }

      return false;
    }).toList();
  }

  /// Masrafları gelişmiş filtreleme ile filtrele
  /// Tüm filtre kriterlerini uygular
  static List<ExpenseModel> filterExpensesAdvanced(List<ExpenseModel> expenses, ExpenseFilter filter) {
    if (!filter.isActive) {
      return expenses;
    }

    return expenses.where((expense) {
      // Metin araması
      if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
        final query = filter.searchQuery!.toLowerCase().trim();
        final descriptionMatch = expense.description.toLowerCase().contains(query);
        final category = ExpenseCategories.getById(expense.category);
        final categoryMatch = category != null && category.name.toLowerCase().contains(query);
        final amountMatch = expense.amount.toString().contains(query);

        if (!descriptionMatch && !categoryMatch && !amountMatch) {
          return false;
        }
      }

      // Kategori filtresi (çoklu seçim)
      if (filter.categoryIds != null && filter.categoryIds!.isNotEmpty) {
        if (!filter.categoryIds!.contains(expense.category)) {
          return false;
        }
      }

      // Minimum tutar filtresi
      if (filter.minAmount != null && expense.amount < filter.minAmount!) {
        return false;
      }

      // Maksimum tutar filtresi
      if (filter.maxAmount != null && expense.amount > filter.maxAmount!) {
        return false;
      }

      // Başlangıç tarihi filtresi
      if (filter.startDate != null) {
        final startOfDay = DateTime(filter.startDate!.year, filter.startDate!.month, filter.startDate!.day);
        final expenseDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
        if (expenseDate.isBefore(startOfDay)) {
          return false;
        }
      }

      // Bitiş tarihi filtresi
      if (filter.endDate != null) {
        final endOfDay = DateTime(filter.endDate!.year, filter.endDate!.month, filter.endDate!.day, 23, 59, 59);
        if (expense.date.isAfter(endOfDay)) {
          return false;
        }
      }

      // Kişi filtresi (paidBy veya sharedBy içinde)
      if (filter.userId != null) {
        final isPaidBy = expense.paidBy == filter.userId || (expense.paidAmounts?.containsKey(filter.userId) ?? false);
        final isSharedBy = expense.sharedBy.contains(filter.userId);
        if (!isPaidBy && !isSharedBy) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}
