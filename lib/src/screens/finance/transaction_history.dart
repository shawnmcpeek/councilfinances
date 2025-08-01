import 'package:flutter/material.dart';
import '../../utils/logger.dart';
import '../../services/finance_service.dart';
import '../../models/finance_entry.dart';
import '../../models/finance_entry_adapter.dart';
import '../../components/log_display.dart';
import '../../components/finance_entry_edit_dialog.dart';

class TransactionHistory extends StatefulWidget {
  final String organizationId;
  final VoidCallback? ref;

  const TransactionHistory({
    super.key,
    required this.organizationId,
    this.ref,
  });

  @override
  State<TransactionHistory> createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends State<TransactionHistory> {
  final _financeService = FinanceService();
  bool _isLoading = true;
  List<FinanceEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void didUpdateWidget(TransactionHistory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organizationId != widget.organizationId) {
      _loadTransactions();
    }
  }

  // Public method to refresh transactions
  Future<void> refresh() async {
    await _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    if (widget.organizationId.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final entries = await _financeService.getFinanceEntries(
        widget.organizationId,
      );

      if (mounted) {
        setState(() {
          _entries = entries;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return LogDisplay<FinanceEntryAdapter>(
      entries: _entries.map((entry) => FinanceEntryAdapter(entry, hasEditPermission: true, hasDeletePermission: true)).toList(),
      emptyMessage: 'No transactions found',
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onEdit: (adapter) async {
        final updated = await showDialog<FinanceEntry>(
          context: context,
          builder: (context) => FinanceEntryEditDialog(
            entry: adapter.entry,
            organizationId: widget.organizationId,
          ),
        );
        if (updated != null) {
          _loadTransactions();
        }
      },
      onDelete: (adapter) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Entry'),
            content: const Text('Are you sure you want to delete this entry?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
            ],
          ),
        );
        if (confirm == true) {
          await _financeService.deleteFinanceEntry(
            organizationId: widget.organizationId,
            entryId: adapter.entry.id,
            isExpense: adapter.entry.isExpense,
            year: adapter.entry.date.year,
          );
          _loadTransactions();
        }
      },
    );
  }
} 