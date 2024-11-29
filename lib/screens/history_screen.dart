import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  bool _isLoading = false;
  String _error = '';
  String _selectedFilter = 'All Time';

  final List<String> _filters = [
    'Today',
    'This Week',
    'This Month',
    'This Year',
    'All Time',
  ];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final transactions = await StorageService.getTransactions();
      setState(() {
        _transactions = transactions..sort((a, b) => b.date.compareTo(a.date));
        _filterTransactions();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading transactions: $e';
        _isLoading = false;
      });
    }
  }

  void _filterTransactions() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfYear = DateTime(now.year, 1, 1);

    setState(() {
      switch (_selectedFilter) {
        case 'Today':
          _filteredTransactions = _transactions.where((t) {
            final transactionDate = DateTime(t.date.year, t.date.month, t.date.day);
            return transactionDate.isAtSameMomentAs(today);
          }).toList();
          break;
        case 'This Week':
          _filteredTransactions = _transactions.where((t) => t.date.isAfter(startOfWeek.subtract(const Duration(days: 1)))).toList();
          break;
        case 'This Month':
          _filteredTransactions = _transactions.where((t) => t.date.isAfter(startOfMonth.subtract(const Duration(days: 1)))).toList();
          break;
        case 'This Year':
          _filteredTransactions = _transactions.where((t) => t.date.isAfter(startOfYear.subtract(const Duration(days: 1)))).toList();
          break;
        default: // All Time
          _filteredTransactions = List.from(_transactions);
      }
    });
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(
                filter,
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              selectedColor: Theme.of(context).primaryColor,
              backgroundColor: Colors.grey[200],
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                  _filterTransactions();
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Transaction History',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: theme.primaryColor,
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(
                        child: Text(
                          _error,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      )
                    : _filteredTransactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 64,
                                  color: theme.colorScheme.primary.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No transactions yet',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: theme.colorScheme.primary.withOpacity(0.5),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add some transactions to see them here',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onBackground.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredTransactions.length,
                            itemBuilder: (context, index) {
                              final transaction = _filteredTransactions[index];
                              final isIncome = transaction.amount > 0;
                              final amount = transaction.amount.abs();

                              return Dismissible(
                                key: Key(transaction.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  color: theme.colorScheme.error,
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                onDismissed: (direction) async {
                                  try {
                                    await StorageService.deleteTransaction(transaction.id);
                                    setState(() {
                                      _transactions.remove(transaction);
                                      _filterTransactions();
                                    });
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Transaction deleted'),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error deleting transaction: $e'),
                                          backgroundColor: theme.colorScheme.error,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isIncome
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      child: Icon(
                                        isIncome ? Icons.add : Icons.remove,
                                        color: isIncome ? Colors.green : Colors.red,
                                      ),
                                    ),
                                    title: Text(
                                      transaction.description,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    subtitle: Text(
                                      '${transaction.category} • ${DateFormat('MMM d, y').format(transaction.date)}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    trailing: Text(
                                      '${isIncome ? '+' : '-'} ₱${amount.toStringAsFixed(2)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isIncome ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
