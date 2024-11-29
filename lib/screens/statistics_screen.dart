
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../models/transaction.dart';
import '../constants/categories.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => StatisticsScreenState();
}

class StatisticsScreenState extends State<StatisticsScreen> {
  List<Transaction> _transactions = [];
  Map<String, double> _categoryTotals = {};
  double _totalExpenses = 0;
  double _totalIncome = 0;
  bool _isLoading = true;
  bool _showingExpenses = true; // Toggle between income and expenses view
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
    loadData();
  }

  Future<void> loadData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final allTransactions = await StorageService.getTransactions();
      if (!mounted) return;

      final filteredTransactions = _filterTransactionsByDate(allTransactions);
      final expenseTransactions = filteredTransactions.where((t) => t.amount < 0).toList();
      final incomeTransactions = filteredTransactions.where((t) => t.amount > 0).toList();
      
      Map<String, double> expenseTotals = {};
      Map<String, double> incomeTotals = {};
      double totalExpenses = 0;
      double totalIncome = 0;
      
      // Calculate expense totals
      for (var transaction in expenseTransactions) {
        final amount = transaction.amount.abs();
        expenseTotals[transaction.category] = (expenseTotals[transaction.category] ?? 0) + amount;
        totalExpenses += amount;
      }

      // Calculate income totals
      for (var transaction in incomeTransactions) {
        final amount = transaction.amount;
        incomeTotals[transaction.category] = (incomeTotals[transaction.category] ?? 0) + amount;
        totalIncome += amount;
      }

      setState(() {
        _transactions = filteredTransactions;
        _categoryTotals = _showingExpenses ? expenseTotals : incomeTotals;
        _totalExpenses = totalExpenses;
        _totalIncome = totalIncome;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading statistics: $e')),
      );
    }
  }

  List<Transaction> _filterTransactionsByDate(List<Transaction> transactions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfYear = DateTime(now.year, 1, 1);

    switch (_selectedFilter) {
      case 'Today':
        return transactions.where((t) {
          final transactionDate = DateTime(t.date.year, t.date.month, t.date.day);
          return transactionDate.isAtSameMomentAs(today);
        }).toList();
      case 'This Week':
        return transactions.where((t) => t.date.isAfter(startOfWeek.subtract(const Duration(days: 1)))).toList();
      case 'This Month':
        return transactions.where((t) => t.date.isAfter(startOfMonth.subtract(const Duration(days: 1)))).toList();
      case 'This Year':
        return transactions.where((t) => t.date.isAfter(startOfYear.subtract(const Duration(days: 1)))).toList();
      default: // All Time
        return transactions;
    }
  }

  void _toggleView() {
    setState(() {
      _showingExpenses = !_showingExpenses;
      loadData();
    });
  }

  List<PieChartSectionData> _getSections() {
    if (_categoryTotals.isEmpty) return [];

    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.yellow,
      Colors.teal,
      Colors.pink,
    ];

    int colorIndex = 0;
    final total = _showingExpenses ? _totalExpenses : _totalIncome;
    
    return _categoryTotals.entries.map((entry) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${(entry.value / total * 100).toStringAsFixed(1)}%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    if (_categoryTotals.isEmpty) return Container();

    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.yellow,
      Colors.teal,
      Colors.pink,
    ];

    return Column(
      children: _categoryTotals.entries.map((entry) {
        final index = _categoryTotals.keys.toList().indexOf(entry.key);
        final color = colors[index % colors.length];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.key,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '₱${entry.value.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
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
                  loadData();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Statistics',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          TextButton.icon(
            onPressed: _toggleView,
            icon: Icon(
              _showingExpenses ? Icons.arrow_upward : Icons.arrow_downward,
              color: Colors.white,
            ),
            label: Text(
              _showingExpenses ? 'Show Income' : 'Show Expenses',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadData,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _transactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.show_chart,
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
                              const SizedBox(height: 8),
                              Text(
                                'Add transactions to see your statistics',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Card(
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _showingExpenses ? 'Total Expenses' : 'Total Income',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '₱${(_showingExpenses ? _totalExpenses : _totalIncome).toStringAsFixed(2)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                          color: _showingExpenses 
                                            ? Colors.red 
                                            : Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (_categoryTotals.isNotEmpty) ...[
                                Text(
                                  _showingExpenses ? 'Expense Breakdown' : 'Income Breakdown',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 200,
                                  child: PieChart(
                                    PieChartData(
                                      sections: _getSections(),
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 0,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Card(
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: _buildLegend(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
