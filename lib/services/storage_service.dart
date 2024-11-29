
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

class StorageService {
  static const String _balanceKey = 'balance';
  static const String _transactionsKey = 'transactions';
  static const String _categoriesKey = 'categories';

  // Balance methods
  static Future<double> getBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_balanceKey) ?? 0.0;
  }

  static Future<void> setBalance(double balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_balanceKey, balance);
  }

  // Transaction methods
  static Future<List<Transaction>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = prefs.getStringList(_transactionsKey) ?? [];
    return transactionsJson
        .map((json) => Transaction.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<void> addTransaction(Transaction transaction) async {
    final prefs = await SharedPreferences.getInstance();
    final transactions = prefs.getStringList(_transactionsKey) ?? [];
    transactions.add(jsonEncode(transaction.toJson()));
    await prefs.setStringList(_transactionsKey, transactions);

    // Update balance based on transaction type
    final currentBalance = await getBalance();
    final amountChange = transaction.category == 'Income' 
        ? transaction.amount.abs() /
        : -transaction.amount.abs(); 
    await setBalance(currentBalance + amountChange);
  }

  static Future<void> saveTransactions(List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final data = transactions.map((t) => t.toJson()).toList();
    await prefs.setStringList(_transactionsKey, data.map((t) => jsonEncode(t)).toList());

    // Recalculate total balance
    double newBalance = 0.0;
    for (var transaction in transactions) {
      if (transaction.category == 'Income') {
        newBalance += transaction.amount.abs();
      } else {
        newBalance -= transaction.amount.abs();
      }
    }
    await setBalance(newBalance);
  }

  static Future<void> deleteTransaction(String id) async {
    final transactions = await getTransactions();
    transactions.removeWhere((t) => t.id == id);
    await saveTransactions(transactions);
  }

  // Categories methods
  static Future<List<String>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_categoriesKey) ?? 
      ['All', 'Food', 'Transport', 'Shopping', 'Bills', 'Others'];
  }

  static Future<void> setCategories(List<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_categoriesKey, categories);
  }

  static Future<void> deleteCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final categories = await getCategories();
    categories.remove(category);
    await prefs.setStringList(_categoriesKey, categories);
  }
}
