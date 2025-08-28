import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF4A148C);
  static const Color accent = Color(0xFFF50057);

  static const Map<String, Color> categoryColors = {
    'Rent': Color(0xFFE57373),
    'Electricity': Color(0xFFFFD54F),
    'Water': Color(0xFF64B5F6),
    'Internet': Color(0xFF81C784),
    'Subscription': Color(0xFFBA68C8),
    'Loan': Color(0xFF9575CD),
    'Other': Color(0xFFB0BEC5),
  };

  static const Map<String, Color> categoryBgColors = {
    'Rent': Color(0xFFFFEBEE),
    'Electricity': Color(0xFFFFF8E1),
    'Water': Color(0xFFE3F2FD),
    'Internet': Color(0xFFE8F5E9),
    'Subscription': Color(0xFFF3E5F5),
    'Loan': Color(0xFFEDE7F6),
    'Other': Color(0xFFECEFF1),
  };

  static Color getIconColor(String category) {
    return categoryColors[category] ?? categoryColors['Other']!;
  }

  static Color getIconBgColor(String category) {
    return categoryBgColors[category] ?? categoryBgColors['Other']!;
  }
}
