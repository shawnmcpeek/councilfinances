import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/finance_entry.dart';
import '../utils/logger.dart';
import '../models/payment_method.dart';
import '../models/program.dart';
import '../services/auth_service.dart';

class FinanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

  Future<List<FinanceEntry>> getFinanceEntries(
    String organizationId,
    bool isAssembly,
  ) async {
    try {
      final formattedOrgId = _getFormattedOrgId(organizationId, isAssembly);
      AppLogger.info('=== LOADING FINANCIAL ENTRIES ===');
      AppLogger.info('Organization: $formattedOrgId');
      AppLogger.info('Type: ${isAssembly ? 'Assembly' : 'Council'}');
      
      final List<FinanceEntry> entries = [];
      final currentYear = DateTime.now().year;
      final years = [currentYear, currentYear - 1]; // Current and previous year only
      AppLogger.info('Querying years: ${years.join(", ")}');

      // Get income and expense entries for all relevant years
      final incomeSnapshots = await _getYearlySnapshots(formattedOrgId, years, 'income');
      final expenseSnapshots = await _getYearlySnapshots(formattedOrgId, years, 'expenses');

      // Process income entries
      for (var snapshot in incomeSnapshots) {
        entries.addAll(_processEntries(snapshot, false));
      }

      // Process expense entries
      for (var snapshot in expenseSnapshots) {
        entries.addAll(_processEntries(snapshot, true));
      }

      // Sort all entries by date
      entries.sort((a, b) => b.date.compareTo(a.date));
      
      // Log summary of entries
      final incomeEntries = entries.where((e) => !e.isExpense).toList();
      final expenseEntries = entries.where((e) => e.isExpense).toList();
      final totalIncome = incomeEntries.fold<double>(0, (sum, e) => sum + e.amount);
      final totalExpenses = expenseEntries.fold<double>(0, (sum, e) => sum + e.amount);
      
      AppLogger.info('=== FINANCIAL ENTRIES SUMMARY ===');
      AppLogger.info('Total entries: ${entries.length}');
      AppLogger.info('Income entries: ${incomeEntries.length} (Total: \$${totalIncome.toStringAsFixed(2)})');
      AppLogger.info('Expense entries: ${expenseEntries.length} (Total: \$${totalExpenses.toStringAsFixed(2)})');
      AppLogger.info('Net: \$${(totalIncome - totalExpenses).toStringAsFixed(2)}');
      AppLogger.info('===============================');
      
      return entries;
    } catch (e, stackTrace) {
      AppLogger.error('Error getting finance entries', e);
      AppLogger.error('Stack trace:', stackTrace);
      rethrow;
    }
  }

  Future<List<QuerySnapshot<Map<String, dynamic>>>> _getYearlySnapshots(
    String formattedOrgId,
    List<int> years,
    String type,
  ) async {
    AppLogger.debug('Fetching $type entries for years: ${years.join(", ")}');
    return Future.wait(
      years.map((year) {
        AppLogger.debug('Querying $type collection for year: $year');
        return _firestore
          .collection('organizations')
          .doc(formattedOrgId)
          .collection('finance')
          .doc(type)
          .collection(year.toString())
          .get();
      })
    );
  }

  List<FinanceEntry> _processEntries(QuerySnapshot<Map<String, dynamic>> snapshot, bool isExpense) {
    final entries = <FinanceEntry>[];
    final type = isExpense ? 'expense' : 'income';
    
    AppLogger.info('Processing $type entries: ${snapshot.docs.length} found');
    for (var doc in snapshot.docs) {
      try {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final amount = (data['amount'] as num).toDouble();
        final program = data['programName'] ?? data['program']?['name'] ?? 'Unknown';
        final description = data['description'] ?? 'N/A';
        final paymentMethod = data['paymentMethod'] ?? 'Unknown';
        
        AppLogger.info('$type: ${date.toString().split(' ')[0]} | \$${amount.toStringAsFixed(2)} | $program | $description | $paymentMethod');
        
        // Validate required fields
        if (!_validateRequiredFields(data, doc.id, type)) continue;
        
        // Type validation
        if (!_validateDataTypes(data['date'], data['amount'], doc.id, type)) continue;

        entries.add(FinanceEntry(
          id: doc.id,
          date: date,
          program: Program(
            id: data['programId'] as String,
            name: program,
            category: (data['category'] as String?) ?? 'unknown',
            isSystemDefault: false,
            financialType: isExpense ? FinancialType.expenseOnly : FinancialType.incomeOnly,
            isEnabled: true,
            isAssembly: isExpense,
          ),
          amount: amount,
          paymentMethod: paymentMethod,
          checkNumber: isExpense ? data['checkNumber'] as String? : null,
          description: description,
          isExpense: isExpense,
        ));
      } catch (e, stackTrace) {
        AppLogger.error('Error processing $type entry ${doc.id}', e);
        AppLogger.error('Stack trace for $type entry ${doc.id}:', stackTrace);
      }
    }
    return entries;
  }

  bool _validateRequiredFields(Map<String, dynamic> data, String docId, String type) {
    if (!data.containsKey('date') || 
        !data.containsKey('amount') || 
        !data.containsKey('programId') || 
        !data.containsKey('programName')) {
      AppLogger.error('$type entry $docId missing required fields', data);
      return false;
    }
    return true;
  }

  bool _validateDataTypes(dynamic date, dynamic amount, String docId, String type) {
    if (date is! Timestamp || amount is! num) {
      AppLogger.error('$type entry $docId has invalid data types', {'date': date, 'amount': amount});
      return false;
    }
    return true;
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
      'date': Timestamp.fromDate(date),
      'amount': amount,
      'description': description,
      'programId': programId,
      'programName': programName,
      'paymentMethod': paymentMethod.name,
      if (checkNumber != null) 'checkNumber': checkNumber,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
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
      final docRef = _firestore
          .collection('organizations')
          .doc(formattedOrgId)
          .collection('finance')
          .doc(type)
          .collection(date.year.toString())
          .doc();

      final data = _createEntryData(
        docId: docRef.id,
        date: date,
        amount: amount,
        description: description,
        paymentMethod: paymentMethod,
        programId: programId,
        programName: programName,
        userId: user.uid,
        checkNumber: checkNumber,
      );

      AppLogger.debug('Adding $type entry: $data');
      await docRef.set(data);
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
      
      final List<FinanceEntry> entries = [];

      // Get income entries
      final incomeSnapshot = await _firestore
          .collection('organizations')
          .doc(formattedOrgId)
          .collection('finance')
          .doc('income')
          .collection(year)
          .where('programId', isEqualTo: programId)
          .get();

      // Get expense entries
      final expenseSnapshot = await _firestore
          .collection('organizations')
          .doc(formattedOrgId)
          .collection('finance')
          .doc('expenses')
          .collection(year)
          .where('programId', isEqualTo: programId)
          .get();

      // Process income entries
      entries.addAll(_processEntries(incomeSnapshot, false));

      // Process expense entries
      entries.addAll(_processEntries(expenseSnapshot, true));

      // Sort all entries by date
      entries.sort((a, b) => b.date.compareTo(a.date));
      
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
      final type = isExpense ? 'expenses' : 'income';
      final docRef = _firestore
          .collection('organizations')
          .doc(formattedOrgId)
          .collection('finance')
          .doc(type)
          .collection(year.toString())
          .doc(entryId);
      await docRef.delete();
      AppLogger.debug('Deleted $type entry: $entryId for $formattedOrgId, year $year');
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting finance entry', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateFinanceEntry({
    required String organizationId,
    required String entryId,
    required bool isAssembly,
    required bool isExpense,
    required int year,
    required DateTime date,
    required double amount,
    required String description,
    required PaymentMethod paymentMethod,
    required String programId,
    required String programName,
    String? checkNumber,
  }) async {
    try {
      final formattedOrgId = _getFormattedOrgId(organizationId, isAssembly);
      final type = isExpense ? 'expenses' : 'income';
      final docRef = _firestore
          .collection('organizations')
          .doc(formattedOrgId)
          .collection('finance')
          .doc(type)
          .collection(year.toString())
          .doc(entryId);

      final data = _createEntryData(
        docId: entryId,
        date: date,
        amount: amount,
        description: description,
        paymentMethod: paymentMethod,
        programId: programId,
        programName: programName,
        userId: _authService.currentUser?.uid ?? '',
        checkNumber: checkNumber,
      );

      AppLogger.debug('Updating $type entry: $data');
      await docRef.update(data);
    } catch (e, stackTrace) {
      AppLogger.error('Error updating finance entry', e, stackTrace);
      rethrow;
    }
  }

  Future<List<FinanceEntry>> getFinanceEntriesForYear(
    String organizationId,
    bool isAssembly,
    String year,
  ) async {
    try {
      final formattedOrgId = _getFormattedOrgId(organizationId, isAssembly);
      AppLogger.debug('Getting finance entries for organization: $formattedOrgId, year: $year');
      
      final List<FinanceEntry> entries = [];

      // Get income entries
      final incomeSnapshot = await _firestore
          .collection('organizations')
          .doc(formattedOrgId)
          .collection('finance')
          .doc('income')
          .collection(year)
          .get();

      // Get expense entries
      final expenseSnapshot = await _firestore
          .collection('organizations')
          .doc(formattedOrgId)
          .collection('finance')
          .doc('expenses')
          .collection(year)
          .get();

      // Process income entries
      entries.addAll(_processEntries(incomeSnapshot, false));

      // Process expense entries
      entries.addAll(_processEntries(expenseSnapshot, true));

      // Sort all entries by date
      entries.sort((a, b) => b.date.compareTo(a.date));
      
      AppLogger.debug('Returning ${entries.length} entries for year $year');
      return entries;
    } catch (e, stackTrace) {
      AppLogger.error('Error getting finance entries for year', e);
      AppLogger.error('Stack trace:', stackTrace);
      rethrow;
    }
  }
} 