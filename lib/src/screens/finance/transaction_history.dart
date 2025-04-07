import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../utils/logger.dart';
import '../../services/finance_service.dart';
import '../../models/finance_entry.dart';
import '../../models/payment_method.dart';

class TransactionHistory extends StatefulWidget {
  final String organizationId;
  final bool isAssembly;

  const TransactionHistory({
    super.key,
    required this.organizationId,
    required this.isAssembly,
  });

  @override
  State<TransactionHistory> createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends State<TransactionHistory> {
  final _financeService = FinanceService();
  final _currencyFormat = NumberFormat.currency(symbol: '\$');
  
  bool _isLoading = true;
  Map<int, Map<int, List<FinanceEntry>>> _groupedEntries = {};
  Set<int> _expandedYears = {};
  Set<String> _expandedMonths = {};

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void didUpdateWidget(TransactionHistory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organizationId != widget.organizationId || 
        oldWidget.isAssembly != widget.isAssembly) {
      _loadTransactions();
    }
  }

  Future<void> _loadTransactions() async {
    if (widget.organizationId.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final entries = await _financeService.getFinanceEntries(
        widget.organizationId,
        widget.isAssembly,
      );

      // Group entries by year and month
      final grouped = <int, Map<int, List<FinanceEntry>>>{};
      for (var entry in entries) {
        final year = entry.date.year;
        final month = entry.date.month;
        
        grouped.putIfAbsent(year, () => {});
        grouped[year]!.putIfAbsent(month, () => []);
        grouped[year]![month]!.add(entry);
      }

      // Sort entries within each month by date (newest first)
      for (var year in grouped.keys) {
        for (var month in grouped[year]!.keys) {
          grouped[year]![month]!.sort((a, b) => b.date.compareTo(a.date));
        }
      }

      if (mounted) {
        setState(() {
          _groupedEntries = grouped;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading transactions', e);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transactions: ${e.toString()}')),
        );
      }
    }
  }

  void _toggleYear(int year) {
    setState(() {
      if (_expandedYears.contains(year)) {
        _expandedYears.remove(year);
        // Remove all month expansions for this year
        _expandedMonths.removeWhere((key) => key.startsWith('$year-'));
      } else {
        _expandedYears.add(year);
      }
    });
  }

  void _toggleMonth(int year, int month) {
    final key = '$year-$month';
    setState(() {
      if (_expandedMonths.contains(key)) {
        _expandedMonths.remove(key);
      } else {
        _expandedMonths.add(key);
      }
    });
  }

  String _formatMonth(int month) {
    return DateFormat('MMMM').format(DateTime(2000, month));
  }

  Color _getEntryColor(FinanceEntry entry, bool isEven) {
    final baseColor = entry.isExpense ? Colors.red : Colors.green;
    return isEven 
      ? Color.alphaBlend(Colors.grey.withOpacity(0.05), baseColor.withOpacity(0.3))
      : baseColor.withOpacity(0.3);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_groupedEntries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No transactions found'),
        ),
      );
    }

    final years = _groupedEntries.keys.toList()..sort((a, b) => b.compareTo(a));
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: years.length,
      itemBuilder: (context, yearIndex) {
        final year = years[yearIndex];
        final isYearExpanded = _expandedYears.contains(year);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                year.toString(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              trailing: Icon(
                isYearExpanded ? Icons.expand_less : Icons.expand_more,
              ),
              onTap: () => _toggleYear(year),
            ),
            if (isYearExpanded) ...[
              for (var month in _groupedEntries[year]!.keys.toList()..sort((a, b) => b.compareTo(a)))
                _buildMonthSection(year, month),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMonthSection(int year, int month) {
    final monthKey = '$year-$month';
    final isMonthExpanded = _expandedMonths.contains(monthKey);
    final entries = _groupedEntries[year]![month]!;
    
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              _formatMonth(month),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            trailing: Icon(
              isMonthExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: () => _toggleMonth(year, month),
          ),
          if (isMonthExpanded)
            Column(
              children: [
                // Header row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 3), // Space for indicator
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Date',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Description',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Amount',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                // Entries
                ...entries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final financeEntry = entry.value;
                  return Container(
                    decoration: BoxDecoration(
                      color: index.isEven ? Colors.grey.withOpacity(0.05) : null,
                      border: Border(
                        left: BorderSide(
                          color: financeEntry.isExpense ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              DateFormat('MM/dd/yy').format(financeEntry.date),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  financeEntry.program.name,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  financeEntry.description,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (financeEntry.checkNumber != null)
                                  Text(
                                    'Check #${financeEntry.checkNumber}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              _currencyFormat.format(financeEntry.amount),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: financeEntry.isExpense ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                // Monthly total
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    border: Border(
                      top: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Total Income
                              Row(
                                children: [
                                  Text(
                                    'Total Income: ',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Text(
                                    _currencyFormat.format(
                                      entries.where((entry) => !entry.isExpense)
                                        .fold<double>(0, (sum, entry) => sum + entry.amount),
                                    ),
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              // Total Expenses
                              Row(
                                children: [
                                  Text(
                                    'Total Expenses: ',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Text(
                                    _currencyFormat.format(
                                      entries.where((entry) => entry.isExpense)
                                        .fold<double>(0, (sum, entry) => sum + entry.amount),
                                    ),
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Net Total with divider
                              Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.grey.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Text(
                                      'Net Total: ',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _currencyFormat.format(
                                        entries.fold<double>(
                                          0,
                                          (sum, entry) => sum + (entry.isExpense ? -entry.amount : entry.amount),
                                        ),
                                      ),
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: entries.fold<double>(
                                          0,
                                          (sum, entry) => sum + (entry.isExpense ? -entry.amount : entry.amount),
                                        ) >= 0 ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
} 