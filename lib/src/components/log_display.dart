import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/logger.dart';

/// A generic entry that can be displayed in the log
abstract class LogEntry {
  String get id;
  DateTime get date;
  String get title;
  String get subtitle;
  Map<String, String> get details;
  bool get canEdit;
  bool get canDelete;
}

class LogDisplay<T extends LogEntry> extends StatefulWidget {
  final List<T> entries;
  final String emptyMessage;
  final Function(T entry)? onEdit;
  final Function(T entry)? onDelete;
  final Function(T entry)? onView;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const LogDisplay({
    super.key,
    required this.entries,
    this.emptyMessage = 'No entries found',
    this.onEdit,
    this.onDelete,
    this.onView,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  State<LogDisplay<T>> createState() => _LogDisplayState<T>();
}

class _LogDisplayState<T extends LogEntry> extends State<LogDisplay<T>> {
  final Set<String> _expandedYears = {};
  final Set<String> _expandedMonths = {};
  late Map<int, Map<int, List<T>>> _groupedEntries;
  bool _isVisible = false;

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

  Widget _buildToggleButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_isVisible ? 'Hide Log' : 'View Log'),
        const SizedBox(width: 8),
        Switch(
          value: _isVisible,
          onChanged: (value) {
            AppLogger.debug('Log visibility toggle changed to: $value');
            setState(() => _isVisible = value);
          },
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

  void _showEntryDetails(T entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entry.details.entries.map((detail) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.key,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      detail.value,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
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
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: AppTheme.smallSpacing),
      child: ListView.builder(
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        padding: EdgeInsets.zero,
        itemCount: years.length,
        itemBuilder: (context, yearIndex) {
          final year = years[yearIndex];
          final yearKey = year.toString();
          final isYearExpanded = _expandedYears.contains(yearKey);
          final months = _groupedEntries[year]!.keys.toList()..sort((a, b) => b.compareTo(a));

          return Column(
            children: [
              // Year header
              InkWell(
                onTap: () => _toggleYear(yearKey),
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 26),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        isYearExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                      ),
                      const SizedBox(width: AppTheme.smallSpacing),
                      Text(
                        yearKey,
                        style: AppTheme.subheadingStyle,
                      ),
                    ],
                  ),
                ),
              ),
              if (isYearExpanded)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: months.length,
                  itemBuilder: (context, monthIndex) {
                    final month = months[monthIndex];
                    final monthKey = '$yearKey-$month';
                    final isMonthExpanded = _expandedMonths.contains(monthKey);
                    final entries = _groupedEntries[year]![month]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Month header
                        InkWell(
                          onTap: () => _toggleMonth(monthKey),
                          child: Container(
                            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 13),
                            padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing, vertical: AppTheme.smallSpacing),
                            child: Row(
                              children: [
                                Icon(
                                  isMonthExpanded ? Icons.expand_less : Icons.expand_more,
                                  size: 16,
                                ),
                                const SizedBox(width: AppTheme.smallSpacing),
                                Text(
                                  formatMonth(month),
                                  style: AppTheme.bodyStyle,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isMonthExpanded)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: entries.length,
                            itemBuilder: (context, entryIndex) => _buildEntryRow(entries[entryIndex], entryIndex),
                          ),
                      ],
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEntryRow(T entry, int index) {
    final isEven = index.isEven;
    
    return InkWell(
      onTap: () => _showEntryDetails(entry),
      child: Container(
        decoration: BoxDecoration(
          color: isEven ? Colors.grey.withValues(alpha: 13) : null,
          border: Border(
            left: BorderSide(
              color: _getEntryColor(entry),
              width: 3,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacing),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: AppTheme.labelStyle,
                    ),
                    if (entry.details['Description']?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: AppTheme.smallSpacing),
                        child: Text(
                          entry.details['Description'] ?? '',
                          style: AppTheme.bodyStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              // Date, Hours and Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatDate(entry.date),
                    style: AppTheme.labelStyle.copyWith(fontFamily: 'monospace'),
                  ),
                  Text(
                    entry.subtitle,
                    style: AppTheme.bodyStyle.copyWith(fontFamily: 'monospace'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEntryColor(T entry) {
    // Only check for expense type if it's a financial entry
    if (entry.details.containsKey('Type')) {
      final isExpense = entry.details['Type'] == 'Expense';
      return isExpense 
          ? AppTheme.errorColor.withValues(alpha: 50)
          : AppTheme.primaryColor.withValues(alpha: 50);
    }
    // Default color for non-financial entries
    return AppTheme.secondaryColor.withValues(alpha: 50);
  }
} 