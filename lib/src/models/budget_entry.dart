import 'package:cloud_firestore/cloud_firestore.dart';

enum BudgetStatus {
  draft,
  submitted;

  String get displayName {
    switch (this) {
      case BudgetStatus.draft:
        return 'Draft';
      case BudgetStatus.submitted:
        return 'Submitted';
    }
  }
}

class BudgetEntry {
  final String id;
  final String programName;
  final double income;
  final double expenses;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final String? updatedBy;
  final BudgetStatus status;

  BudgetEntry({
    required this.id,
    required this.programName,
    required this.income,
    required this.expenses,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
    this.updatedBy,
    this.status = BudgetStatus.draft,
  });

  factory BudgetEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BudgetEntry(
      id: doc.id,
      programName: data['programName'] as String,
      income: (data['income'] as num).toDouble(),
      expenses: (data['expenses'] as num).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] as String,
      updatedBy: data['updatedBy'] as String?,
      status: data['status'] != null 
          ? BudgetStatus.values.firstWhere(
              (s) => s.name == data['status'],
              orElse: () => BudgetStatus.draft)
          : BudgetStatus.draft,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'programName': programName,
      'income': income,
      'expenses': expenses,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (updatedBy != null) 'updatedBy': updatedBy,
      'status': status.name,
    };
  }

  double get total => income - expenses;

  BudgetEntry copyWith({
    String? id,
    String? programName,
    double? income,
    double? expenses,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    BudgetStatus? status,
  }) {
    return BudgetEntry(
      id: id ?? this.id,
      programName: programName ?? this.programName,
      income: income ?? this.income,
      expenses: expenses ?? this.expenses,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      status: status ?? this.status,
    );
  }
} 