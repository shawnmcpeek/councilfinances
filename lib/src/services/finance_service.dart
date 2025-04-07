import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/finance_entry.dart';
import '../utils/logger.dart';
import '../models/payment_method.dart';
import '../models/program.dart';
import '../services/auth_service.dart';

class FinanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  Future<List<FinanceEntry>> getFinanceEntries(String organizationId, bool isAssembly) async {
    try {
      final orgPrefix = isAssembly ? 'A' : 'C';
      final formattedOrgId = '${orgPrefix}${organizationId.padLeft(6, '0')}';
      AppLogger.debug('Getting finance entries for organization: $formattedOrgId');
      
      final List<FinanceEntry> entries = [];
      final currentYear = DateTime.now().year;
      AppLogger.debug('Current year from DateTime.now(): $currentYear');
      
      final years = [currentYear, currentYear - 1]; // Current and previous year only
      AppLogger.debug('Querying years: ${years.join(", ")}');

      // Get income entries for all relevant years
      AppLogger.debug('Fetching income entries for years: ${years.join(", ")}');
      final incomeSnapshots = await Future.wait(
        years.map((year) {
          AppLogger.debug('Querying income collection for year: $year');
          return _firestore
            .collection('organizations')
            .doc(formattedOrgId)
            .collection('finance')
            .doc('income')
            .collection(year.toString())
            .get();
        })
      );

      // Get expense entries for all relevant years
      AppLogger.debug('Fetching expense entries for years: ${years.join(", ")}');
      final expenseSnapshots = await Future.wait(
        years.map((year) {
          AppLogger.debug('Querying expense collection for year: $year');
          return _firestore
            .collection('organizations')
            .doc(formattedOrgId)
            .collection('finance')
            .doc('expenses')
            .collection(year.toString())
            .get();
        })
      );

      // Convert income entries
      AppLogger.debug('Processing income entries');
      for (var snapshot in incomeSnapshots) {
        AppLogger.debug('Processing income snapshot with ${snapshot.docs.length} documents');
        for (var doc in snapshot.docs) {
          try {
            final data = doc.data();
            AppLogger.debug('Processing income document ${doc.id}: $data');
            
            // Validate required fields
            if (!data.containsKey('date') || 
                !data.containsKey('amount') || 
                !data.containsKey('programId') || 
                !data.containsKey('programName')) {
              AppLogger.error('Income entry ${doc.id} missing required fields', data);
              continue;
            }

            final date = data['date'];
            final amount = data['amount'];
            
            // Type validation
            if (date is! Timestamp || amount is! num) {
              AppLogger.error('Income entry ${doc.id} has invalid data types', data);
              continue;
            }

            entries.add(FinanceEntry(
              id: doc.id,
              date: date.toDate(),
              program: Program(
                id: data['programId'] as String,
                name: data['programName'] as String,
                category: (data['category'] as String?) ?? 'unknown',
                isSystemDefault: false,
                financialType: FinancialType.incomeOnly,
              ),
              amount: amount.toDouble(),
              paymentMethod: (data['paymentMethod'] as String?) ?? 'Unknown',
              description: (data['description'] as String?) ?? '',
              isExpense: false,
            ));
          } catch (e, stackTrace) {
            AppLogger.error('Error processing income entry ${doc.id}', e);
            AppLogger.error('Stack trace for income entry ${doc.id}:', stackTrace);
          }
        }
      }

      // Convert expense entries
      AppLogger.debug('Processing expense entries');
      for (var snapshot in expenseSnapshots) {
        AppLogger.debug('Processing expense snapshot with ${snapshot.docs.length} documents');
        for (var doc in snapshot.docs) {
          try {
            final data = doc.data();
            AppLogger.debug('Processing expense document ${doc.id}: $data');
            
            // Validate required fields
            if (!data.containsKey('date') || 
                !data.containsKey('amount') || 
                !data.containsKey('programId') || 
                !data.containsKey('programName')) {
              AppLogger.error('Expense entry ${doc.id} missing required fields', data);
              continue;
            }

            final date = data['date'];
            final amount = data['amount'];
            
            // Type validation
            if (date is! Timestamp || amount is! num) {
              AppLogger.error('Expense entry ${doc.id} has invalid data types', data);
              continue;
            }

            entries.add(FinanceEntry(
              id: doc.id,
              date: date.toDate(),
              program: Program(
                id: data['programId'] as String,
                name: data['programName'] as String,
                category: (data['category'] as String?) ?? 'unknown',
                isSystemDefault: false,
                financialType: FinancialType.expenseOnly,
              ),
              amount: amount.toDouble(),
              paymentMethod: (data['paymentMethod'] as String?) ?? 'Unknown',
              checkNumber: data['checkNumber'] as String?,
              description: (data['description'] as String?) ?? '',
              isExpense: true,
            ));
          } catch (e, stackTrace) {
            AppLogger.error('Error processing expense entry ${doc.id}', e);
            AppLogger.error('Stack trace for expense entry ${doc.id}:', stackTrace);
          }
        }
      }

      // Sort all entries by date
      entries.sort((a, b) => b.date.compareTo(a.date));
      
      AppLogger.debug('Returning ${entries.length} entries');
      return entries;
    } catch (e, stackTrace) {
      AppLogger.error('Error getting finance entries', e);
      AppLogger.error('Stack trace:', stackTrace);
      rethrow;
    }
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
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User must be logged in to add entries');

      final orgPrefix = isAssembly ? 'A' : 'C';
      final formattedOrgId = '${orgPrefix}${organizationId.padLeft(6, '0')}';

      final docRef = _firestore
          .collection('organizations')
          .doc(formattedOrgId)
          .collection('finance')
          .doc('income')
          .collection(date.year.toString())
          .doc();

      final data = {
        'id': docRef.id,
        'date': Timestamp.fromDate(date),
        'amount': amount,
        'description': description,
        'programId': programId,
        'programName': programName,
        'paymentMethod': paymentMethod.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': user.uid,
        'updatedBy': user.uid,
      };

      AppLogger.debug('Adding income entry: $data');
      await docRef.set(data);
    } catch (e) {
      AppLogger.error('Error adding income entry', e);
      rethrow;
    }
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
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User must be logged in to add entries');

      final orgPrefix = isAssembly ? 'A' : 'C';
      final formattedOrgId = '${orgPrefix}${organizationId.padLeft(6, '0')}';

      final docRef = _firestore
          .collection('organizations')
          .doc(formattedOrgId)
          .collection('finance')
          .doc('expenses')
          .collection(date.year.toString())
          .doc();

      final data = {
        'id': docRef.id,
        'date': Timestamp.fromDate(date),
        'amount': amount,
        'description': description,
        'paymentMethod': paymentMethod.name,
        'programId': programId,
        'programName': programName,
        'checkNumber': checkNumber,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': user.uid,
        'updatedBy': user.uid,
      };

      AppLogger.debug('Adding expense entry: $data');
      await docRef.set(data);
    } catch (e) {
      AppLogger.error('Error adding expense entry', e);
      rethrow;
    }
  }
} 