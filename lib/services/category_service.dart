import 'package:shared_preferences/shared_preferences.dart';
import '../constants/categories.dart';

class CategoryService {
  static const String _categoriesKey = 'custom_categories';
  static const List<String> _defaultCategories = [
    'Income',
    'Food',
    'Transportation',
    'Shopping',
    'Bills',
    'Entertainment',
    'Education',
    'Others',
  ];

  // Get all categories including custom ones
  static Future<List<String>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final customCategories = prefs.getStringList(_categoriesKey) ?? [];
    return [..._defaultCategories, ...customCategories];
  }

  // Add a new custom category
  static Future<bool> addCategory(String category) async {
    if (category.isEmpty) return false;
    
    final prefs = await SharedPreferences.getInstance();
    final customCategories = prefs.getStringList(_categoriesKey) ?? [];
    
    // Check if category already exists in default or custom categories
    if (_defaultCategories.contains(category) || customCategories.contains(category)) {
      return false;
    }

    customCategories.add(category);
    return prefs.setStringList(_categoriesKey, customCategories);
  }

  // Remove a custom category
  static Future<bool> removeCategory(String category) async {
    // Cannot remove default categories
    if (_defaultCategories.contains(category)) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final customCategories = prefs.getStringList(_categoriesKey) ?? [];
    
    if (!customCategories.contains(category)) {
      return false;
    }

    customCategories.remove(category);
    return prefs.setStringList(_categoriesKey, customCategories);
  }

  // Check if a category is a default category
  static bool isDefaultCategory(String category) {
    return _defaultCategories.contains(category);
  }
}
