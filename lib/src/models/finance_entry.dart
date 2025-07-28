import 'program.dart';

class FinanceEntry {
  final String id;
  final DateTime date;
  final Program program;
  final double amount;
  final String? paymentMethod;
  final String? checkNumber;
  final String? description;
  final bool isExpense;

  FinanceEntry({
    required this.id,
    required this.date,
    required this.program,
    required this.amount,
    this.paymentMethod,
    this.checkNumber,
    this.description,
    required this.isExpense,
  });

  factory FinanceEntry.fromMap(Map<String, dynamic> data) {
    return FinanceEntry(
      id: data['id'] as String,
      date: DateTime.parse(data['date'] as String),
      program: Program.fromMap({
        'id': data['program_id'] as String,
        'name': data['program_name'] as String,
        'category': '',
        'isSystemDefault': false,
        'financialType': 'both',
        'isEnabled': true,
      }),
      amount: (data['amount'] as num).toDouble(),
      paymentMethod: data['payment_method'] as String?,
      checkNumber: data['check_number'] as String?,
      description: data['description'] as String?,
      isExpense: data['is_expense'] as bool,
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