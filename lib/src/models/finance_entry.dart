import 'package:cloud_firestore/cloud_firestore.dart';
import 'program.dart';

class FinanceEntry {
  final String id;
  final DateTime date;
  final Program program;
  final double amount;
  final String paymentMethod;
  final String? checkNumber;
  final String description;
  final bool isExpense;

  FinanceEntry({
    required this.id,
    required this.date,
    required this.program,
    required this.amount,
    required this.paymentMethod,
    this.checkNumber,
    required this.description,
    required this.isExpense,
  });

  factory FinanceEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FinanceEntry(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      program: Program.fromMap(data['program'] as Map<String, dynamic>),
      amount: (data['amount'] as num).toDouble(),
      paymentMethod: data['paymentMethod'] as String,
      checkNumber: data['checkNumber'] as String?,
      description: data['description'] as String,
      isExpense: data['isExpense'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'program': program.toMap(),
      'amount': amount,
      'paymentMethod': paymentMethod,
      'checkNumber': checkNumber,
      'description': description,
      'isExpense': isExpense,
    };
  }
} 