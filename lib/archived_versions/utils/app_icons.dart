import 'package:flutter/material.dart';

class AppIcons {
  static const Map<String, IconData> categoryIcons = {
    'rent': Icons.house_rounded,
    'electricity': Icons.lightbulb_outline_rounded,
    'water': Icons.water_drop_outlined,
    'internet': Icons.wifi_rounded,
    'subscription': Icons.subscriptions_outlined,
    'loan': Icons.account_balance_wallet_outlined,
    'other': Icons.category_rounded,
  };

  static IconData getIconData(String category) {
    return categoryIcons[category.toLowerCase()] ?? categoryIcons['other']!;
  }
}
