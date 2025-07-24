import 'package:supabase_flutter/supabase_flutter.dart';

class BudgetEntry {
  final String id;
  final String organizationId;
  final String programId;
  final String year;
  final double income;
  final double expenses;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;
  final String status;

  BudgetEntry({
    required this.id,
    required this.organizationId,
    required this.programId,
    required this.year,
    required this.income,
    required this.expenses,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    required this.status,
  });

  factory BudgetEntry.fromMap(Map<String, dynamic> map) {
    return BudgetEntry(
      id: map['id'] as String,
      organizationId: map['organization_id'] as String,
      programId: map['program_id'] as String,
      year: map['year'] as String? ?? '',
      income: (map['income'] as num?)?.toDouble() ?? 0.0,
      expenses: (map['expenses'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      createdBy: map['created_by'] as String? ?? '',
      updatedBy: map['updated_by'] as String? ?? '',
      status: map['status'] as String? ?? 'draft',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organization_id': organizationId,
      'program_id': programId,
      'year': year,
      'income': income,
      'expenses': expenses,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
      'updated_by': updatedBy,
      'status': status,
    };
  }
}

class BudgetService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<BudgetEntry>> getBudgetEntries(String organizationId, String year) async {
    final response = await _supabase
        .from('budget_entries')
        .select()
        .eq('organization_id', organizationId)
        .eq('year', year);
    return (response as List)
        .map((e) => BudgetEntry.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsertBudgetEntry(BudgetEntry entry) async {
    await _supabase.from('budget_entries').upsert(entry.toMap());
  }

  Future<void> upsertBudgetEntries(List<BudgetEntry> entries) async {
    final data = entries.map((e) => e.toMap()).toList();
    await _supabase.from('budget_entries').upsert(data);
  }

  Future<void> finalizeBudget(String organizationId, String year) async {
    await _supabase
        .from('budget_entries')
        .update({'status': 'finalized'})
        .eq('organization_id', organizationId)
        .eq('year', year);
  }

  Future<List<BudgetEntry>> getPreviousYearBudgetEntries(String organizationId, String prevYear) async {
    final response = await _supabase
        .from('budget_entries')
        .select()
        .eq('organization_id', organizationId)
        .eq('year', prevYear);
    return (response as List)
        .map((e) => BudgetEntry.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  bool isBudgetLocked(String year) {
    final now = DateTime.now();
    final budgetYear = int.tryParse(year) ?? 0;
    final lockDate = DateTime(budgetYear, 1, 1);
    return now.isAfter(lockDate) || now.isAtSameMomentAs(lockDate);
  }
} 