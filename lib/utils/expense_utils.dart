import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';

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
    return snapshot.docs
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Firebase document ID'sini kullan, data içindeki id'yi override et
          data['id'] = doc.id;
          return ExpenseModel.fromJson(data);
        })
        .toList();
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
}

