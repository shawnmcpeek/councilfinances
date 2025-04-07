import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/form1728p_program.dart';
import '../utils/logger.dart';

class ProgramEntryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveProgramEntry({
    required String organizationId,
    required Form1728PCategory category,
    required Form1728PProgram program,
    required int hours,
    required double disbursement,
    required String description,
    required DateTime date,
  }) async {
    try {
      // Ensure organization ID is properly formatted
      if (!organizationId.startsWith('C') && !organizationId.startsWith('A')) {
        throw Exception('Invalid organization ID format: $organizationId');
      }

      final currentYear = DateTime.now().year.toString();
      
      // Reference to the program's document in the year subcollection
      final programRef = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('program_entries')
          .doc(currentYear)
          .collection(category.name)
          .doc(program.id);

      // Get the existing entry if it exists
      final doc = await programRef.get();
      
      if (doc.exists) {
        // Update existing entry by adding to the current values
        final existingData = doc.data() as Map<String, dynamic>;
        final existingHours = existingData['hours'] as int? ?? 0;
        final existingDisbursement = existingData['disbursement'] as double? ?? 0.0;

        await programRef.update({
          'hours': existingHours + hours,
          'disbursement': existingDisbursement + disbursement,
          'lastUpdated': FieldValue.serverTimestamp(),
          'entries': FieldValue.arrayUnion([{
            'hours': hours,
            'disbursement': disbursement,
            'description': description,
            'date': date.toIso8601String(),
            'timestamp': Timestamp.now(),
          }]),
        });

        AppLogger.debug(
          'Updated program entry: ${program.name}, '
          'Total Hours: ${existingHours + hours}, '
          'Total Disbursement: ${existingDisbursement + disbursement}'
        );
      } else {
        // Create new entry
        await programRef.set({
          'programId': program.id,
          'programName': program.name,
          'category': category.name,
          'hours': hours,
          'disbursement': disbursement,
          'created': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'entries': [{
            'hours': hours,
            'disbursement': disbursement,
            'description': description,
            'date': date.toIso8601String(),
            'timestamp': Timestamp.now(),
          }],
        });

        AppLogger.debug(
          'Created new program entry: ${program.name}, '
          'Hours: $hours, '
          'Disbursement: $disbursement'
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error saving program entry', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProgramEntry({
    required String organizationId,
    required Form1728PCategory category,
    required String programId,
    String? year,
  }) async {
    try {
      final yearStr = year ?? DateTime.now().year.toString();
      
      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('program_entries')
          .doc(yearStr)
          .collection(category.name)
          .doc(programId)
          .get();

      if (!doc.exists) {
        return {
          'hours': 0,
          'disbursement': 0.0,
        };
      }

      final data = doc.data() as Map<String, dynamic>;
      return {
        'hours': data['hours'] as int? ?? 0,
        'disbursement': data['disbursement'] as double? ?? 0.0,
      };
    } catch (e, stackTrace) {
      AppLogger.error('Error getting program entry', e, stackTrace);
      rethrow;
    }
  }
} 