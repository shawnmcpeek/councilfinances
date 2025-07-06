import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/finance_entry_adapter.dart';
import 'package:intl/intl.dart';

/// A generic entry that can be displayed in the log
abstract class LogEntry {
  String get id;
  DateTime get date;
  String get title;
  String get subtitle;
  Map<String, String> get details;
  bool get canEdit;
  bool get canDelete;
  BoxDecoration? get decoration => null;
}

class LogDisplay<T extends LogEntry> extends StatefulWidget {
  final List<T> entries;
  final String emptyMessage;
  final Function(T entry)? onEdit;
  final Function(T entry)? onDelete;
  final Function(T entry)? onView;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Future<void> Function()? onRefresh;

  const LogDisplay({
    super.key,
    required this.entries,
    this.emptyMessage = 'No entries found',
    this.onEdit,
    this.onDelete,
    this.onView,
    this.shrinkWrap = false,
    this.physics,
    this.onRefresh,
  });

  @override
  State<LogDisplay<T>> createState() => _LogDisplayState<T>();
}

class _LogDisplayState<T extends LogEntry> extends State<LogDisplay<T>> {
  final Set<String> _expandedYears = {};
  final Set<String> _expandedMonths = {};
  late Map<int, Map<int, List<T>>> _groupedEntries;
  bool _isVisible = false;
  final _currencyFormat = NumberFormat.currency(symbol: '\$');

  @override
  void initState() {
    super.initState();
    _groupEntries();
  }

  @override
  void didUpdateWidget(LogDisplay<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entries != oldWidget.entries) {
      _groupEntries();
    }
  }

  void _groupEntries() {
    final grouped = <int, Map<int, List<T>>>{};
    
    // Group entries by year and month
    for (var entry in widget.entries) {
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

    _groupedEntries = grouped;
  }

  Widget _buildMonthSummary(List<T> entries) {
    if (entries.isEmpty || entries.first is! FinanceEntryAdapter) return const SizedBox();

    final financeEntries = entries.map((e) => e as FinanceEntryAdapter).toList();
    final totalIncome = financeEntries
        .where((entry) => !entry.entry.isExpense)
        .fold<double>(0, (sum, entry) => sum + entry.entry.amount);
    
    final totalExpenses = financeEntries
        .where((entry) => entry.entry.isExpense)
        .fold<double>(0, (sum, entry) => sum + entry.entry.amount);
    
    final netTotal = totalIncome - totalExpenses;

    return Card(
      margin: EdgeInsets.all(AppTheme.smallSpacing),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Monthly Summary',
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.smallSpacing),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Income:'),
                Text(
                  _currencyFormat.format(totalIncome),
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            ),
            SizedBox(height: AppTheme.smallSpacing),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Expenses:'),
                Text(
                  _currencyFormat.format(totalExpenses),
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
            Divider(height: AppTheme.spacing),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Net Total:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _currencyFormat.format(netTotal),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: netTotal >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_isVisible ? 'Hide Log' : 'View Log'),
        const SizedBox(width: 8),
        Switch(
          value: _isVisible,
          onChanged: (value) => setState(() => _isVisible = value),
        ),
      ],
    );
  }

  void _toggleYear(String yearKey) {
    setState(() {
      if (_expandedYears.contains(yearKey)) {
        _expandedYears.remove(yearKey);
        // Also collapse all months within this year
        _expandedMonths.removeWhere((key) => key.startsWith('$yearKey-'));
      } else {
        _expandedYears.add(yearKey);
      }
    });
  }

  void _toggleMonth(String monthKey) {
    setState(() {
      if (_expandedMonths.contains(monthKey)) {
        _expandedMonths.remove(monthKey);
      } else {
        _expandedMonths.add(monthKey);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToggleButton(),
        if (_isVisible) ...[
          if (widget.entries.isEmpty)
            Padding(
              padding: EdgeInsets.all(AppTheme.spacing),
              child: Center(child: Text(widget.emptyMessage)),
            )
          else
            _buildLogContent(),
        ],
      ],
    );
  }

  Widget _buildLogContent() {
    final years = _groupedEntries.keys.toList()..sort((a, b) => b.compareTo(a));
    
    final listView = ListView.builder(
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      itemCount: years.length,
      itemBuilder: (context, yearIndex) {
        final year = years[yearIndex];
        final yearKey = year.toString();
        final isYearExpanded = _expandedYears.contains(yearKey);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                yearKey,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              trailing: Icon(
                isYearExpanded ? Icons.expand_less : Icons.expand_more,
              ),
              onTap: () => _toggleYear(yearKey),
            ),
            if (isYearExpanded)
              for (var month in _groupedEntries[year]!.keys.toList()..sort((a, b) => b.compareTo(a)))
                _buildMonthSection(year, month),
          ],
        );
      },
    );

    // Wrap with RefreshIndicator if onRefresh is provided
    if (widget.onRefresh != null) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: listView,
      );
    }
    
    return listView;
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
              DateFormat('MMMM').format(DateTime(2000, month)),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            trailing: Icon(
              isMonthExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: () => _toggleMonth(monthKey),
          ),
          if (isMonthExpanded) ...[
            _buildMonthSummary(entries),
            ...entries.map((entry) => Container(
              decoration: entry.decoration,
              child: ListTile(
                title: Text(entry.title),
                subtitle: Text(entry.subtitle),
                onTap: () {
                  if (widget.onView != null) {
                    widget.onView!(entry);
                  }
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (entry.canEdit && widget.onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => widget.onEdit!(entry),
                      ),
                    if (entry.canDelete && widget.onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => widget.onDelete!(entry),
                      ),
                  ],
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }
} 