import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';
import '../models/hours_entry.dart';
import 'auth_service.dart';

class HoursService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Singleton pattern
  static final HoursService _instance = HoursService._internal();
  factory HoursService() => _instance;
  HoursService._internal();

  String _formatOrganizationId(String organizationId, bool isAssembly) {
    if (organizationId.isEmpty) return '';
    if (organizationId.startsWith('C') || organizationId.startsWith('A')) return organizationId;
    
    final prefix = isAssembly ? 'A' : 'C';
    return '$prefix${organizationId.padLeft(6, '0')}';
  }

  Future<void> addHoursEntry(HoursEntry entry, bool isAssembly) async {
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      final formattedOrgId = _formatOrganizationId(entry.organizationId, isAssembly);
      final docRef = _firestore.collection('organizations')
          .doc(formattedOrgId)
          .collection('hours')
          .doc();

      final data = entry.toMap()..addAll({
        'id': docRef.id,
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      AppLogger.debug('Adding hours entry: $data');
      await docRef.set(data);
    } catch (e) {
      AppLogger.error('Error adding hours entry', e);
      rethrow;
    }
  }

  Future<void> updateHoursEntry(HoursEntry entry, bool isAssembly) async {
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      final formattedOrgId = _formatOrganizationId(entry.organizationId, isAssembly);
      final data = entry.toMap()..addAll({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.debug('Updating hours entry: $data');
      await _firestore.collection('organizations')
          .doc(formattedOrgId)
          .collection('hours')
          .doc(entry.id)
          .update(data);
    } catch (e) {
      AppLogger.error('Error updating hours entry', e);
      rethrow;
    }
  }

  Future<void> deleteHoursEntry(String organizationId, String entryId, bool isAssembly) async {
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      final formattedOrgId = _formatOrganizationId(organizationId, isAssembly);
      AppLogger.debug('Deleting hours entry: $entryId');
      await _firestore.collection('organizations')
          .doc(formattedOrgId)
          .collection('hours')
          .doc(entryId)
          .delete();
    } catch (e) {
      AppLogger.error('Error deleting hours entry', e);
      rethrow;
    }
  }

  Stream<List<HoursEntry>> getHoursEntries(String organizationId, bool isAssembly) {
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      final formattedOrgId = _formatOrganizationId(organizationId, isAssembly);
      AppLogger.debug('Getting hours entries for organization: $formattedOrgId and user: ${user.uid}');
      
      return _firestore.collection('organizations')
          .doc(formattedOrgId)
          .collection('hours')
          .where('userId', isEqualTo: user.uid)
          .orderBy('startTime', descending: true)
          .limit(20)
          .snapshots()
          .map((snapshot) {
            AppLogger.debug('Received ${snapshot.docs.length} hours entries from Firestore');
            return snapshot.docs
                .map((doc) => HoursEntry.fromFirestore(doc))
                .toList();
          });
    } catch (e) {
      AppLogger.error('Error getting hours entries', e);
      rethrow;
    }
  }

  Future<List<HoursEntry>> getHoursEntriesByYear(
    String organizationId,
    bool isAssembly,
    int year,
  ) async {
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      final formattedOrgId = _formatOrganizationId(organizationId, isAssembly);
      final startOfYear = DateTime(year);
      final endOfYear = DateTime(year + 1);

      final snapshot = await _firestore.collection('organizations')
          .doc(formattedOrgId)
          .collection('hours')
          .where('userId', isEqualTo: user.uid)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear))
          .where('startTime', isLessThan: Timestamp.fromDate(endOfYear))
          .orderBy('startTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => HoursEntry.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting hours entries for year $year', e);
      rethrow;
    }
  }
} 