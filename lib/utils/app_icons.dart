import 'package:flutter/material.dart';

class AppIcons {
  static IconData getIcon(String category) {
    switch (category.toLowerCase()) {
      case 'rent':
      case 'housing':
        return Icons.home;
      case 'utilities':
        return Icons.flash_on;
      case 'food':
      case 'groceries':
        return Icons.restaurant;
      case 'transport':
      case 'transportation':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'health':
      case 'healthcare':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      case 'shopping':
        return Icons.shopping_bag;
      case 'insurance':
        return Icons.security;
      case 'subscription':
        return Icons.subscriptions;
      case 'loan':
        return Icons.account_balance;
      case 'credit card':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  static String getCategoryName(String category) {
    switch (category.toLowerCase()) {
      case 'rent':
        return 'Rent';
      case 'housing':
        return 'Housing';
      case 'utilities':
        return 'Utilities';
      case 'food':
        return 'Food';
      case 'groceries':
        return 'Groceries';
      case 'transport':
        return 'Transport';
      case 'transportation':
        return 'Transportation';
      case 'entertainment':
        return 'Entertainment';
      case 'health':
        return 'Health';
      case 'healthcare':
        return 'Healthcare';
      case 'education':
        return 'Education';
      case 'shopping':
        return 'Shopping';
      case 'insurance':
        return 'Insurance';
      case 'subscription':
        return 'Subscription';
      case 'loan':
        return 'Loan';
      case 'credit card':
        return 'Credit Card';
      default:
        return 'Other';
    }
  }
}
