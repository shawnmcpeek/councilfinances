import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';
import '../services/user_service.dart';
import '../services/program_service.dart';
import '../models/program.dart';
import '../reports/audit_field_map.dart';

class AuditFirestoreDataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  /// Fetches and calculates all Firestore data for audit reports
  /// Returns a Map with all calculated Firestore values
  Future<Map<String, dynamic>> getAuditFirestoreData(String period, int year) async {
    try {
      AppLogger.info('=== STARTING FIRESTORE DATA FETCH ===');
      AppLogger.info('Period: $period, Year: $year');

      // 1. Get user profile for organization info
      final userProfile = await _userService.getUserProfile();
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      // 2. Get date range for the period (use AuditFieldMap logic)
      final dateRange = AuditFieldMap.getDateRangeForPeriod(period, year);
      final organizationId = userProfile.getOrganizationId(false);

      AppLogger.info('Organization ID: $organizationId');
      AppLogger.info('Date range: ${dateRange.start} to ${dateRange.end}');

      // 3. Load all active programs (system + custom)
      final programService = ProgramService();
      final systemPrograms = await programService.loadSystemPrograms();
      await programService.loadProgramStates(systemPrograms, organizationId, false);
      final activeSystemPrograms = systemPrograms.councilPrograms.values.expand((list) => list).where((p) => p.isEnabled).toList();
      final customPrograms = await programService.getCustomPrograms(organizationId, false);
      final activeCustomPrograms = customPrograms.where((p) => p.isEnabled).toList();
      final allPrograms = [...activeSystemPrograms, ...activeCustomPrograms];

      // 4. Build lookup: programId/name -> Program
      final Map<String, Program> programLookup = {};
      for (final p in allPrograms) {
        programLookup[p.id.toLowerCase()] = p;
        programLookup[p.name.toLowerCase()] = p;
      }

      // 5. Get transactions for the period
      final transactions = await _getTransactionsForPeriod(
        organizationId,
        dateRange.start,
        dateRange.end,
      );

      // 6. Process transactions and calculate all Firestore-based values
      final firestoreData = _processTransactions(transactions, programLookup);

      // 7. Add basic organization info
      firestoreData['council_number'] = userProfile.councilNumber.toString().padLeft(6, '0');
      firestoreData['organization_name'] = 'Council ${userProfile.councilNumber}';
      firestoreData['year'] = _getYearSuffix(year);

      AppLogger.info('=== FIRESTORE DATA FETCH COMPLETE ===');
      AppLogger.info('Total transactions processed: ${transactions.length}');
      AppLogger.info('Calculated fields: ${firestoreData.keys.join(', ')}');

      return firestoreData;
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching Firestore audit data', e, stackTrace);
      print('EXCEPTION: $e');
      print('STACKTRACE: $stackTrace');
      rethrow;
    }
  }

  String _getYearSuffix(int year) {
    return year.toString().substring(2);
  }

  Future<List<Map<String, dynamic>>> _getTransactionsForPeriod(
    String organizationId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final List<Map<String, dynamic>> allTransactions = [];
    final years = <int>{startDate.year, endDate.year};
    
    AppLogger.info('Loading transactions for period: ${startDate.toString()} to ${endDate.toString()}');
    
    for (final year in years) {
      try {
        AppLogger.info('Loading transactions for year: $year');
        
        // Fetch income
        final incomeSnapshot = await _db
            .collection('organizations')
            .doc(organizationId)
            .collection('finance')
            .doc('income')
            .collection(year.toString())
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
            .get();
            
        AppLogger.info('Found ${incomeSnapshot.docs.length} income transactions for year $year');
        
        for (final doc in incomeSnapshot.docs) {
          final data = doc.data();
          final date = (data['date'] as Timestamp).toDate();
          final amount = (data['amount'] as num).toDouble();
          final program = data['programName'] ?? data['program']?['name'] ?? 'Unknown';
          final description = data['description'] ?? 'N/A';
          final paymentMethod = data['paymentMethod'] ?? 'Unknown';
          
          AppLogger.info('INCOME: Date: $date, Amount: \$${amount.toStringAsFixed(2)}, Program: $program, Description: $description, Payment: $paymentMethod');
          
          allTransactions.add({
            'program': program,
            'programId': data['programId'] ?? data['program']?['id'] ?? '',
            'amount': amount,
            'date': date,
            'type': 'income',
            'description': description,
            'paymentMethod': paymentMethod
          });
        }

        // Fetch expenses
        final expenseSnapshot = await _db
            .collection('organizations')
            .doc(organizationId)
            .collection('finance')
            .doc('expenses')
            .collection(year.toString())
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
            .get();
            
        AppLogger.info('Found ${expenseSnapshot.docs.length} expense transactions for year $year');
        
        for (final doc in expenseSnapshot.docs) {
          final data = doc.data();
          final date = (data['date'] as Timestamp).toDate();
          final amount = (data['amount'] as num).toDouble();
          final program = data['programName'] ?? data['program']?['name'] ?? 'Unknown';
          final description = data['description'] ?? 'N/A';
          final paymentMethod = data['paymentMethod'] ?? 'Unknown';
          
          AppLogger.info('EXPENSE: Date: $date, Amount: \$${amount.toStringAsFixed(2)}, Program: $program, Description: $description, Payment: $paymentMethod');
          
          allTransactions.add({
            'program': program,
            'programId': data['programId'] ?? data['program']?['id'] ?? '',
            'amount': amount,
            'date': date,
            'type': 'expense',
            'description': description,
            'paymentMethod': paymentMethod
          });
        }
      } catch (e, stackTrace) {
        AppLogger.error('Error fetching transactions for year $year', e, stackTrace);
        continue;
      }
    }
    
    AppLogger.info('Total transactions loaded: ${allTransactions.length}');
    return allTransactions;
  }

  Map<String, dynamic> _processTransactions(List<Map<String, dynamic>> transactions, Map<String, Program> programLookup) {
    final Map<String, dynamic> firestoreData = {};
    
    // Initialize all program totals
    double membershipDues = 0.0;
    double interestEarned = 0.0;
    double supremePerCapita = 0.0;
    double statePerCapita = 0.0;
    double councilPrograms = 0.0;
    double otherCouncilPrograms = 0.0;
    
    // Process each transaction
    for (final transaction in transactions) {
      final programName = _normalizeProgram(transaction['program']);
      final amount = (transaction['amount'] as num).toDouble();
      final type = transaction['type'] as String;
      
      if (type == 'income') {
        // Map programs to audit fields
        if (programName.contains('membership') || programName.contains('dues')) {
          membershipDues += amount;
        } else if (programName.contains('interest')) {
          interestEarned += amount;
        } else if (programName.contains('supreme') || programName.contains('per capita')) {
          supremePerCapita += amount;
        } else if (programName.contains('state')) {
          statePerCapita += amount;
        } else {
          // Check if it's a council program
          final program = programLookup[programName];
          if (program != null && program.isEnabled) {
            councilPrograms += amount;
          } else {
            otherCouncilPrograms += amount;
          }
        }
      } else if (type == 'expense') {
        // Map expense programs
        if (programName.contains('postage') || 
            programName.contains('insurance') || 
            programName.contains('membership') ||
            programName.contains('advertising') ||
            programName.contains('conference') ||
            programName.contains('convention') ||
            programName.contains('seminarian')) {
          otherCouncilPrograms += amount;
        } else {
          // Check if it's a council program
          final program = programLookup[programName];
          if (program != null && program.isEnabled) {
            councilPrograms += amount;
          } else {
            otherCouncilPrograms += amount;
          }
        }
      }
    }
    
    // Store the calculated values
    firestoreData['membership_dues'] = _formatCurrency(membershipDues);
    firestoreData['interest_earned'] = _formatCurrency(interestEarned);
    firestoreData['supreme_per_capita'] = _formatCurrency(supremePerCapita);
    firestoreData['state_per_capita'] = _formatCurrency(statePerCapita);
    firestoreData['council_program'] = _formatCurrency(councilPrograms);
    firestoreData['other_council_programs'] = _formatCurrency(otherCouncilPrograms);
    
    AppLogger.info('=== FIRESTORE CALCULATED VALUES ===');
    AppLogger.info('membership_dues: ${firestoreData['membership_dues']}');
    AppLogger.info('interest_earned: ${firestoreData['interest_earned']}');
    AppLogger.info('supreme_per_capita: ${firestoreData['supreme_per_capita']}');
    AppLogger.info('state_per_capita: ${firestoreData['state_per_capita']}');
    AppLogger.info('council_program: ${firestoreData['council_program']}');
    AppLogger.info('other_council_programs: ${firestoreData['other_council_programs']}');
    
    return firestoreData;
  }

  String _normalizeProgram(dynamic program) {
    return (program as String?)?.toLowerCase().trim() ?? '';
  }

  String _formatCurrency(double value) {
    return value.toStringAsFixed(2);
  }
}

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange(this.start, this.end);
} 