import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Masraf kategorileri
class ExpenseCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class ExpenseCategories {
  static const List<ExpenseCategory> all = [
    food,
    travel,
    cosmetics,
    health,
    entertainment,
    bills,
    clothing,
    other,
  ];

  static const food = ExpenseCategory(
    id: 'food',
    name: 'Yeme-İçme',
    icon: Icons.restaurant,
    color: AppColors.primary,
  );

  static const travel = ExpenseCategory(
    id: 'travel',
    name: 'Seyahat',
    icon: Icons.flight,
    color: AppColors.info,
  );

  static const cosmetics = ExpenseCategory(
    id: 'cosmetics',
    name: 'Kozmetik',
    icon: Icons.face,
    color: AppColors.secondary,
  );

  static const health = ExpenseCategory(
    id: 'health',
    name: 'Sağlık',
    icon: Icons.local_hospital,
    color: AppColors.error,
  );

  static const entertainment = ExpenseCategory(
    id: 'entertainment',
    name: 'Eğlence',
    icon: Icons.movie,
    color: AppColors.accent,
  );

  static const bills = ExpenseCategory(
    id: 'bills',
    name: 'Faturalar',
    icon: Icons.receipt,
    color: AppColors.warning,
  );

  static const clothing = ExpenseCategory(
    id: 'clothing',
    name: 'Giyim',
    icon: Icons.checkroom,
    color: AppColors.secondaryDark,
  );

  static const other = ExpenseCategory(
    id: 'other',
    name: 'Diğer',
    icon: Icons.category,
    color: AppColors.greyDark,
  );

  /// ID'ye göre kategori bul
  static ExpenseCategory? getById(String id) {
    try {
      return all.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  /// İsme göre kategori bul
  static ExpenseCategory? getByName(String name) {
    try {
      return all.firstWhere((category) => category.name == name);
    } catch (e) {
      return null;
    }
  }
}

