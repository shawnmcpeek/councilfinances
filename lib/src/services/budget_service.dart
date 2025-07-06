import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_entry.dart';
import '../utils/logger.dart';
import 'auth_service.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Singleton pattern
  static final BudgetService _instance = BudgetService._internal();
  factory BudgetService() => _instance;
  BudgetService._internal();

  String _getFormattedOrgId(String organizationId, bool isAssembly) {
    // If the ID already starts with C or A, return it as is
    if (organizationId.startsWith('C') || organizationId.startsWith('A')) {
      return organizationId;
    }
    
    // Otherwise, add the prefix
    final orgPrefix = isAssembly ? 'A' : 'C';
    return '$orgPrefix${organizationId.padLeft(6, '0')}';
  }

  Future<List<BudgetEntry>> getBudgetEntries(String organizationId, bool isAssembly, String year) async {
    try {
      final formattedOrgId = _getFormattedOrgId(organizationId, isAssembly);
      AppLogger.debug('Getting budget entries for organization: $formattedOrgId, year: $year');
      
      final snapshot = await _firestore
          .collection('organizations')
          .doc(formattedOrgId)
          .collection('budget')
          .doc(year)
          .collection('entries')
          .get();

      return snapshot.docs.map((doc) => BudgetEntry.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error getting budget entries', e);
      AppLogger.error('Stack trace:', stackTrace);
      rethrow;
    }
  }

  Future<BudgetEntry?> getBudgetEntry(String organizationId, bool isAssembly, String year, String programName) async {
    try {
      final formattedOrgId = _getFormattedOrgId(organizationId, isAssembly);
      AppLogger.debug('Getting budget entry for organization: $formattedOrgId, year: $year, program: $programName');
      
      final querySnapshot = await _firestore
          .collection('organizations')
          .doc(formattedOrgId)
          .collection('budget')
          .doc(year)
          .collection('entries')
          .where('programName', isEqualTo: programName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;
      return BudgetEntry.fromFirestore(querySnapshot.docs.first);
    } catch (e, stackTrace) {
      AppLogger.error('Error getting budget entry', e);
      AppLogger.error('Stack trace:', stackTrace);
      rethrow;
    }
  }

  Future<void> saveBudgetEntry({
    required String organizationId,
    required bool isAssembly,
    required String year,
    required String programName,
    required double income,
    required double expenses,
  }) async {
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User must be logged in to save budget entries');

      final formattedOrgId = _getFormattedOrgId(organizationId, isAssembly);
      final docRef = _firestore
        .collection('organizations')
        .doc(formattedOrgId)
        .collection('budget')
        .doc(year)
        .collection('entries')
        .doc(programName);

      final docSnapshot = await docRef.get();

      final data = {
        'programName': programName,
        'income': income,
        'expenses': expenses,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user.uid,
        'status': BudgetStatus.draft.name,
      };

      if (!docSnapshot.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
        data['createdBy'] = user.uid;
      }

      AppLogger.debug('Saving budget entry: $data');
      AppLogger.debug('Firestore write path: ' + docRef.path);
      try {
        await docRef.set(data, SetOptions(merge: true));
      } catch (e, stackTrace) {
        AppLogger.error('Firestore set failed', e);
        AppLogger.error('Stack trace:', stackTrace);
        rethrow;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error saving budget entry', e);
      AppLogger.error('Stack trace:', stackTrace);
      rethrow;
    }
  }

  Future<void> submitBudget(String organizationId, bool isAssembly, String year) async {
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User must be logged in to submit budget');

      final formattedOrgId = _getFormattedOrgId(organizationId, isAssembly);
      
      // Get all entries for the year
      final entries = await getBudgetEntries(organizationId, isAssembly, year);
      
      // Create a batch write
      final batch = _firestore.batch();
      final collection = _firestore
          .collection('organizations')
          .doc(formattedOrgId)
          .collection('budget')
          .doc(year)
          .collection('entries');

      // Update all entries to submitted status
      for (var entry in entries) {
        final docRef = collection.doc(entry.id);
        AppLogger.debug('Firestore batch update path: ' + docRef.path);
        batch.update(docRef, {
          'status': BudgetStatus.submitted.name,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': user.uid,
        });
      }

      try {
        await batch.commit();
      } catch (e, stackTrace) {
        AppLogger.error('Firestore batch commit failed', e);
        AppLogger.error('Stack trace:', stackTrace);
        rethrow;
      }
      AppLogger.debug('Successfully submitted budget for year: $year');
    } catch (e, stackTrace) {
      AppLogger.error('Error submitting budget', e);
      AppLogger.error('Stack trace:', stackTrace);
      rethrow;
    }
  }

  Future<bool> isBudgetSubmitted(String organizationId, bool isAssembly, String year) async {
    try {
      final entries = await getBudgetEntries(organizationId, isAssembly, year);
      return entries.isNotEmpty && entries.every((entry) => entry.status == BudgetStatus.submitted);
    } catch (e, stackTrace) {
      AppLogger.error('Error checking budget status', e);
      AppLogger.error('Stack trace:', stackTrace);
      rethrow;
    }
  }

  Future<void> copyPreviousYearBudget(String organizationId, bool isAssembly, String fromYear, String toYear) async {
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User must be logged in to copy budget');

      final formattedOrgId = _getFormattedOrgId(organizationId, isAssembly);
      AppLogger.debug('Copying budget from $fromYear to $toYear for organization: $formattedOrgId');

      // Get all entries from the previous year
      final fromSnapshot = await _firestore
          .collection('organizations')
          .doc(formattedOrgId)
          .collection('budget')
          .doc(fromYear)
          .collection('entries')
          .get();

      // Create a batch write
      final batch = _firestore.batch();
      final toCollection = _firestore
          .collection('organizations')
          .doc(formattedOrgId)
          .collection('budget')
          .doc(toYear)
          .collection('entries');

      // Copy each entry to the new year
      for (var doc in fromSnapshot.docs) {
        final data = doc.data();
        final newDocRef = toCollection.doc();
        
        batch.set(newDocRef, {
          ...data,
          'status': BudgetStatus.draft.name, // Always copy as draft
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': user.uid,
        });
      }

      await batch.commit();
      AppLogger.debug('Successfully copied budget from $fromYear to $toYear');
    } catch (e, stackTrace) {
      AppLogger.error('Error copying budget', e);
      AppLogger.error('Stack trace:', stackTrace);
      rethrow;
    }
  }
} 