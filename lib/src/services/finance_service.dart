import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/finance_entry.dart';
import '../utils/logger.dart';
import '../models/payment_method.dart';

import '../services/auth_service.dart';

class FinanceService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  Future<List<FinanceEntry>> getFinanceEntries(String organizationId) async {
    try {
      AppLogger.debug('Getting finance entries for organization: $organizationId');
      
      final currentYear = DateTime.now().year;
      final startOfPreviousYear = DateTime(currentYear - 1, 1, 1);
      
      AppLogger.debug('Querying from $startOfPreviousYear to now');

      // Get all finance entries for the organization from previous year to now
      final response = await _supabase
          .from('finance_entries')
          .select()
          .eq('organization_id', organizationId)
          .gte('date', startOfPreviousYear.toIso8601String())
          .order('date', ascending: false);

      final entries = response.map((data) => FinanceEntry.fromMap(data)).toList();
      
      AppLogger.debug('Returning ${entries.length} entries');
      return entries;
    } catch (e, stackTrace) {
      AppLogger.error('Error getting finance entries', e);
      AppLogger.error('Stack trace:', stackTrace);
      rethrow;
    }
  }

  Map<String, dynamic> _createEntryData({
    required String docId,
    required DateTime date,
    required double amount,
    required String description,
    required PaymentMethod paymentMethod,
    required String programId,
    required String programName,
    required String userId,
    String? checkNumber,
  }) {
    return {
      'id': docId,
      'date': date.toIso8601String(),
      'amount': amount,
      'description': description,
      'program_id': programId,
      'program_name': programName,
      'payment_method': paymentMethod.name,
      if (checkNumber != null) 'check_number': checkNumber,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'created_by': userId,
      'updated_by': userId,
    };
  }

  Future<void> addIncomeEntry({
    required String organizationId,
    required DateTime date,
    required double amount,
    required String description,
    required PaymentMethod paymentMethod,
    required String programId,
    required String programName,
  }) async {
    await _addEntry(
      organizationId: organizationId,
      date: date,
      amount: amount,
      description: description,
      paymentMethod: paymentMethod,
      programId: programId,
      programName: programName,
      type: 'income',
    );
  }

  Future<void> addExpenseEntry({
    required String organizationId,
    required DateTime date,
    required double amount,
    required String description,
    required PaymentMethod paymentMethod,
    required String programId,
    required String programName,
    String? checkNumber,
  }) async {
    await _addEntry(
      organizationId: organizationId,
      date: date,
      amount: amount,
      description: description,
      paymentMethod: paymentMethod,
      programId: programId,
      programName: programName,
      type: 'expenses',
      checkNumber: checkNumber,
    );
  }

  Future<void> _addEntry({
    required String organizationId,
    required DateTime date,
    required double amount,
    required String description,
    required PaymentMethod paymentMethod,
    required String programId,
    required String programName,
    required String type,
    String? checkNumber,
  }) async {
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User must be logged in to add entries');

      final data = _createEntryData(
        docId: '${user.id}_${DateTime.now().millisecondsSinceEpoch}', // Generate unique id
        date: date,
        amount: amount,
        description: description,
        paymentMethod: paymentMethod,
        programId: programId,
        programName: programName,
        userId: user.id,
        checkNumber: checkNumber,
      );

      // Add organization and type info
      data['organization_id'] = organizationId;
      data['is_expense'] = type == 'expenses';

      AppLogger.debug('Adding $type entry: $data');
      await _supabase
          .from('finance_entries')
          .insert(data);
    } catch (e) {
      AppLogger.error('Error adding $type entry', e);
      rethrow;
    }
  }

  Future<List<FinanceEntry>> getFinanceEntriesForProgram(
    String organizationId,
    String programId,
    String year,
  ) async {
    try {
      final yearInt = int.parse(year);
      final startOfYear = DateTime(yearInt, 1, 1);
      final endOfYear = DateTime(yearInt, 12, 31, 23, 59, 59);
      
      AppLogger.debug('Getting finance entries for organization: $organizationId, program: $programId, year: $year');
      
      final response = await _supabase
          .from('finance_entries')
          .select()
          .eq('organization_id', organizationId)
          .eq('program_id', programId)
          .gte('date', startOfYear.toIso8601String())
          .lte('date', endOfYear.toIso8601String())
          .order('date', ascending: false);

      final entries = response.map((data) => FinanceEntry.fromMap(data)).toList();
      
      AppLogger.debug('Returning ${entries.length} entries for program $programId');
      return entries;
    } catch (e, stackTrace) {
      AppLogger.error('Error getting finance entries for program', e);
      AppLogger.error('Stack trace:', stackTrace);
      rethrow;
    }
  }

  Future<void> deleteFinanceEntry({
    required String organizationId,
    required String entryId,
    required bool isExpense,
    required int year,
  }) async {
    try {
      await _supabase
          .from('finance_entries')
          .delete()
          .eq('id', entryId);
      AppLogger.debug('Deleted finance entry: $entryId for $organizationId, year $year');
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting finance entry', e, stackTrace);
      rethrow;
    }
  }
} 