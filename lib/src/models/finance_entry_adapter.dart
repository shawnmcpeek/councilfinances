import '../components/log_display.dart';
import '../models/finance_entry.dart';
import '../utils/formatters.dart';
import 'package:flutter/material.dart';

class FinanceEntryAdapter implements LogEntry {
  final FinanceEntry entry;
  final bool hasEditPermission;
  final bool hasDeletePermission;

  FinanceEntryAdapter(this.entry, {
    this.hasEditPermission = false,
    this.hasDeletePermission = false,
  });

  @override
  String get id => entry.id;

  @override
  DateTime get date => entry.date;

  @override
  String get title => entry.program.name;

  @override
  String get subtitle => '${formatDate(entry.date)} - ${formatCurrency(entry.amount)}';

  @override
  Map<String, String> get details => {
    'Date': formatDate(entry.date),
    'Program': entry.program.name,
    'Amount': formatCurrency(entry.amount),
    'Payment Method': entry.paymentMethod ?? 'Not specified',
    if (entry.checkNumber != null) 'Check Number': entry.checkNumber!,
    if (entry.description != null && entry.description!.isNotEmpty) 'Description': entry.description!,
    'Type': entry.isExpense ? 'Expense' : 'Income',
  };

  @override
  bool get canEdit => hasEditPermission;

  @override
  bool get canDelete => hasDeletePermission;

  @override
  BoxDecoration? get decoration => BoxDecoration(
    border: Border(
      left: BorderSide(
        color: entry.isExpense ? Colors.red : Colors.green,
        width: 3,
      ),
    ),
  );
} 