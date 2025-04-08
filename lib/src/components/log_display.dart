import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

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

  Color _getEntryColor(T entry) {
    // Only check for expense type if it's a financial entry
    if (entry.details.containsKey('Type')) {
      final isExpense = entry.details['Type'] == 'Expense';
      return isExpense 
          ? Colors.red.withAlpha(77)
          : Colors.green.withAlpha(77);
    }
    // Default color for non-financial entries
    return Colors.transparent;
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        isYearExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        yearKey,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              if (isYearExpanded)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  isMonthExpanded ? Icons.expand_less : Icons.expand_more,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  formatMonth(month),
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isMonthExpanded)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
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
          color: isEven ? Colors.grey.withAlpha(13) : null,
          border: Border(
            left: BorderSide(
              color: _getEntryColor(entry),
              width: 3,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Date
              SizedBox(
                width: 80,
                child: Text(
                  formatDate(entry.date),
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(width: 8),
              // Title
              Expanded(
                flex: 2,
                child: Text(entry.title),
              ),
              const SizedBox(width: 8),
              // Subtitle (usually amount)
              Expanded(
                child: Text(
                  entry.subtitle,
                  style: const TextStyle(fontFamily: 'monospace'),
                  textAlign: TextAlign.right,
                ),
              ),
              // Action buttons
              if (widget.onView != null || entry.canEdit || entry.canDelete)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onView != null)
                      IconButton(
                        icon: const Icon(Icons.info_outline, size: 18),
                        onPressed: () => _showEntryDetails(entry),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (entry.canEdit && widget.onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => widget.onEdit!(entry),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (entry.canDelete && widget.onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () => widget.onDelete!(entry),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
} 