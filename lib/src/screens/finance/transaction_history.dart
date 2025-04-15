import 'package:flutter/material.dart';
import '../../utils/logger.dart';
import '../../services/finance_service.dart';
import '../../models/finance_entry.dart';
import '../../models/finance_entry_adapter.dart';
import '../../components/log_display.dart';

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
      entries: _entries.map((entry) => FinanceEntryAdapter(entry)).toList(),
      emptyMessage: 'No transactions found',
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }
} 