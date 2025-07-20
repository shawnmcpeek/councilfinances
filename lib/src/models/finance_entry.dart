import 'program.dart';

class FinanceEntry {
  final String id;
  final DateTime date;
  final Program program;
  final double amount;
  final String paymentMethod;
  final String? checkNumber;
  final String? description;
  final bool isExpense;

  FinanceEntry({
    required this.id,
    required this.date,
    required this.program,
    required this.amount,
    required this.paymentMethod,
    this.checkNumber,
    this.description,
    required this.isExpense,
  });

  factory FinanceEntry.fromMap(Map<String, dynamic> data) {
    return FinanceEntry(
      id: data['id'] as String,
      date: DateTime.parse(data['date'] as String),
      program: Program.fromMap(data['program'] as Map<String, dynamic>),
      amount: (data['amount'] as num).toDouble(),
      paymentMethod: data['paymentMethod'] as String,
      checkNumber: data['checkNumber'] as String?,
      description: data['description'] as String?,
      isExpense: data['isExpense'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'program': program.toMap(),
      'amount': amount,
      'paymentMethod': paymentMethod,
      'checkNumber': checkNumber,
      if (description != null) 'description': description,
      'isExpense': isExpense,
    };
  }
} 