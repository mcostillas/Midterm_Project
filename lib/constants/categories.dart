import 'package:flutter/material.dart';

class Categories {
  static List<String> all = [
    'All',
    'Income',
    'Food',
    'Transportation',
    'Shopping',
    'Bills',
    'Entertainment',
    'Education',
    'Others',
  ];

  static List<String> expenseOnly = [
    'Food',
    'Transportation',
    'Shopping',
    'Bills',
    'Entertainment',
    'Education',
    'Others',
  ];

  static IconData getIcon(String category) {
    switch (category.toLowerCase()) {
      case 'income':
        return Icons.attach_money;
      case 'food':
        return Icons.restaurant;
      case 'transportation':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_cart;
      case 'bills':
        return Icons.receipt;
      case 'entertainment':
        return Icons.movie;
      case 'education':
        return Icons.school;
      case 'others':
        return Icons.category;
      case 'all':
        return Icons.list;
      default:
        return Icons.label;
    }
  }

  static bool isExpenseCategory(String category) {
    return category != 'Income' && category != 'All';
  }
}
