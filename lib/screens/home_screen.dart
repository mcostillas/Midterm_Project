/*
  Author: Costillas, Celeste T.
  Section: BSCS 3-3
  Date Created: October 2023
  Program Description: Home screen of the Expense Tracker app showing the list of transactions
*/

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';
import '../services/category_service.dart';
import '../widgets/app_logo.dart';
import 'add_expense_screen.dart';
import 'statistics_screen.dart';
import 'history_screen.dart';
import '../constants/categories.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  String _selectedCategory = Categories.all.first;
  bool _isLoading = false;
  String _error = '';
  double _balance = 0.0;
  int _selectedIndex = 0;
  final GlobalKey<StatisticsScreenState> _statisticsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final transactions = await StorageService.getTransactions();
    final balance = await StorageService.getBalance();
    
    if (mounted) {
      setState(() {
        _transactions = transactions;
        _balance = balance;
        _filteredTransactions = _filterTransactions();
      });
    }
  }

  double get _totalIncome {
    return _transactions
        .where((t) => t.category == 'Income')
        .fold(0.0, (sum, t) => sum + t.amount.abs());
  }

  double get _totalExpenses {
    return _transactions
        .where((t) => t.category != 'Income')
        .fold(0.0, (sum, t) => sum + t.amount.abs());
  }

  double _calculateBalance() {
    double totalIncome = 0;
    double totalExpenses = 0;

    for (final transaction in _transactions) {
      if (transaction.category == 'Income') {
        totalIncome += transaction.amount;
      } else {
        totalExpenses += transaction.amount.abs();
      }
    }

    return totalIncome - totalExpenses;
  }

  List<Transaction> _filterTransactions() {
    if (_selectedCategory == 'All') {
      return List.from(_transactions)
        ..sort((a, b) => b.date.compareTo(a.date));
    }
    return _transactions
        .where((t) => t.category == _selectedCategory)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _filteredTransactions = _filterTransactions();
    });
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          category,
          style: TextStyle(
            color: isSelected ? Colors.white : theme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        onSelected: (selected) => _onCategorySelected(category),
        backgroundColor: theme.primaryColor.withOpacity(0.1),
        selectedColor: theme.primaryColor,
        checkmarkColor: Colors.white,
        showCheckmark: false,
        elevation: 0,
        pressElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.transparent : theme.primaryColor,
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Add Category Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              side: BorderSide(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
              ),
              onPressed: () => _showAddCategoryDialog(),
            ),
          ),
          ...Categories.all.map((category) => Container(
                margin: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: _selectedCategory == category,
                  showCheckmark: false,
                  avatar: Icon(
                    Categories.getIcon(category),
                    size: 18,
                    color: _selectedCategory == category
                        ? Colors.white
                        : Theme.of(context).primaryColor,
                  ),
                  labelStyle: TextStyle(
                    color: _selectedCategory == category
                        ? Colors.white
                        : Theme.of(context).primaryColor,
                  ),
                  backgroundColor: Colors.white,
                  selectedColor: Theme.of(context).primaryColor,
                  side: BorderSide(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                  ),
                  onSelected: (selected) {
                    setState(() => _selectedCategory = selected ? category : 'All');
                  },
                  deleteIcon: category != 'All' && 
                             category != 'Income' && 
                             category != 'Others'
                      ? Icon(
                          Icons.close,
                          size: 18,
                          color: _selectedCategory == category
                              ? Colors.white
                              : Theme.of(context).colorScheme.error,
                        )
                      : null,
                  onDeleted: category != 'All' && 
                            category != 'Income' && 
                            category != 'Others'
                      ? () => _deleteCategory(category)
                      : null,
                ),
              )).toList(),
        ],
      ),
    );
  }

  Future<void> _showAddCategoryDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              hintText: 'Enter category name',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a category name';
              }
              if (Categories.all.contains(value)) {
                return 'Category already exists';
              }
              return null;
            },
            textCapitalization: TextCapitalization.words,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final success = await CategoryService.addCategory(
                  controller.text.trim(),
                );
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Category added successfully')),
                  );
                  Navigator.pop(context);
                  _loadCategories();
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to add category')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(String category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "$category"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await CategoryService.removeCategory(category);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted successfully')),
        );
        setState(() {
          if (_selectedCategory == category) {
            _selectedCategory = 'All';
          }
        });
        _loadCategories();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete category')),
        );
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await CategoryService.getCategories();
      setState(() {
        Categories.all.clear();
        Categories.all.addAll(['All', ...categories]);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: $e')),
        );
      }
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Transportation':
        return Icons.directions_car;
      case 'Shopping':
        return Icons.shopping_cart;
      case 'Bills':
        return Icons.receipt;
      default:
        return Icons.category;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        _loadData(); // Refresh home tab
      } else if (index == 1 && _statisticsKey.currentState != null) {
        _statisticsKey.currentState!.loadData(); // Refresh statistics tab
      }
    });
  }

  Widget _buildBalanceCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Balance',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  NumberFormat.currency(
                    symbol: '₱',
                    decimalDigits: 2,
                  ).format(_balance),
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _editBalance,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editBalance() async {
    final controller = TextEditingController(text: _balance.toString());
    final formKey = GlobalKey<FormFieldState>();

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Balance',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextFormField(
          key: formKey,
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'New Balance',
            prefixText: '₱',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a value';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(double.parse(controller.text));
              }
            },
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      try {
        final difference = result - _balance;
        
        // Create a transaction record for the balance change
        final transaction = Transaction(
          id: const Uuid().v4(),
          description: 'Balance Adjustment',
          amount: difference,
          category: 'Income',
          date: DateTime.now(),
        );
        
        await StorageService.addTransaction(transaction);
        await _loadData(); // This will update both balance and transactions
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Balance updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating balance: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Widget _buildBalanceItem(
    String title,
    double amount,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                NumberFormat.currency(
                  symbol: '₱',
                  decimalDigits: 2,
                ).format(amount),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHomeScreen() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBalanceCard(),
          const SizedBox(height: 24),
          Text(
            'Categories',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildCategories(),
          const SizedBox(height: 24),
          Text(
            'Recent Transactions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _filteredTransactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = _filteredTransactions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Categories.getIcon(transaction.category),
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        title: Text(
                          transaction.description,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          DateFormat('MMM d, y').format(transaction.date),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        trailing: Text(
                          NumberFormat.currency(
                            symbol: '₱',
                            decimalDigits: 2,
                          ).format(transaction.amount),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: transaction.category == 'Income'
                                    ? Colors.green
                                    : Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeScreen(),
          StatisticsScreen(key: _statisticsKey),
          const HistoryScreen(),
          const Center(child: Text('Settings')),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart_outlined),
            activeIcon: Icon(Icons.insert_chart_rounded),
            label: 'Statistics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddExpenseScreen(),
            ),
          );
          if (result == true) {
            setState(() {
              _loadData();
            });
          }
        },
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.add_rounded,
          size: 32,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
