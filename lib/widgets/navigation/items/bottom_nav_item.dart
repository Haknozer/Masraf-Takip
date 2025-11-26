import 'package:flutter/material.dart';

/// Bottom Navigation Bar Item Model
class BottomNavItem {
  final IconData icon;
  final String label;
  final int index;

  const BottomNavItem({required this.icon, required this.label, required this.index});
}

