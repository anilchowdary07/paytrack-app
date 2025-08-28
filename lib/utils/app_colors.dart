import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6366F1);
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static Color getIconColor(String category) {
    switch (category.toLowerCase()) {
      case 'rent':
      case 'housing':
        return const Color(0xFF8B5CF6);
      case 'utilities':
        return const Color(0xFF10B981);
      case 'food':
      case 'groceries':
        return const Color(0xFFF59E0B);
      case 'transport':
      case 'transportation':
        return const Color(0xFF3B82F6);
      case 'entertainment':
        return const Color(0xFFEC4899);
      case 'health':
      case 'healthcare':
        return const Color(0xFFEF4444);
      case 'education':
        return const Color(0xFF06B6D4);
      case 'shopping':
        return const Color(0xFF84CC16);
      case 'insurance':
        return const Color(0xFF6366F1);
      default:
        return const Color(0xFF6B7280);
    }
  }

  static Color getCategoryColor(String category) {
    return getIconColor(category);
  }
}
