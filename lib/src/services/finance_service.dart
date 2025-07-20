import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/finance_entry.dart';
import '../utils/logger.dart';
import '../models/payment_method.dart';

import '../services/auth_service.dart';

class FinanceService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  String _getFormattedOrgId(String organizationId, bool isAssembly) {
    // If the ID already starts with C or A, return it as is
    if (organizationId.startsWith('C') || organizationId.startsWith('A')) {
      return organizationId;
    }
    
    // Otherwise, add the prefix
    final orgPrefix = isAssembly ? 'A' : 'C';
    return '$orgPrefix${organizationId.padLeft(6, '0')}';
  }

  Future<List<FinanceEntry>> getFinanceEntries(String organizationId, bool isAssembly) async {
    try {
      final formattedOrgId = _getFormattedOrgId(organizationId, isAssembly);
      AppLogger.debug('Getting finance entries for organization: $formattedOrgId');
      
      final currentYear = DateTime.now().year;
      final years = [currentYear, currentYear - 1]; // Current and previous year only
      AppLogger.debug('Querying years: ${years.join(", ")}');

      // Get all finance entries for the organization
      final response = await _supabase
          .from('finance_entries')
          .select()
          .eq('organizationId', formattedOrgId)
          .inFilter('year', years.map((y) => y.toString()).toList())
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
      'programId': programId,
      'programName': programName,
      'paymentMethod': paymentMethod.name,
      if (checkNumber != null) 'checkNumber': checkNumber,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'createdBy': userId,
      'updatedBy': userId,
    };
  }

  Future<void> addIncomeEntry({
    required String organizationId,
    required bool isAssembly,
    required DateTime date,
    required double amount,
    required String description,
    required PaymentMethod paymentMethod,
    required String programId,
    required String programName,
  }) async {
    await _addEntry(
      organizationId: organizationId,
      isAssembly: isAssembly,
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
    required bool isAssembly,
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
      isAssembly: isAssembly,
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
    required bool isAssembly,
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

      final formattedOrgId = _getFormattedOrgId(organizationId, isAssembly);
      final data = _createEntryData(
        docId: '', // Supabase will generate the ID
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
      data['organizationId'] = formattedOrgId;
      data['isExpense'] = type == 'expenses';
      data['year'] = date.year.toString();

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
    bool isAssembly,
    String programId,
    String year,
  ) async {
    try {
      final formattedOrgId = _getFormattedOrgId(organizationId, isAssembly);
      AppLogger.debug('Getting finance entries for organization: $formattedOrgId, program: $programId, year: $year');
      
      final response = await _supabase
          .from('finance_entries')
          .select()
          .eq('organizationId', formattedOrgId)
          .eq('programId', programId)
          .eq('year', year)
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
    required bool isAssembly,
    required bool isExpense,
    required int year,
  }) async {
    try {
      final formattedOrgId = _getFormattedOrgId(organizationId, isAssembly);
      await _supabase
          .from('finance_entries')
          .delete()
          .eq('id', entryId);
      AppLogger.debug('Deleted finance entry: $entryId for $formattedOrgId, year $year');
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting finance entry', e, stackTrace);
      rethrow;
    }
  }
} 