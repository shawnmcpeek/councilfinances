import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../models/form1728p_program.dart';
import '../models/program_entry_adapter.dart';
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
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
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
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
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

  Stream<List<ProgramEntry>> getProgramEntries(String organizationId) {
    try {
      AppLogger.debug('getProgramEntries called for organization: $organizationId');
      
      if (!organizationId.startsWith('C') && !organizationId.startsWith('A')) {
        final error = 'Invalid organization ID format: $organizationId';
        AppLogger.error(error);
        throw Exception(error);
      }

      final currentYear = DateTime.now().year.toString();
      final lastYear = (DateTime.now().year - 1).toString();

      AppLogger.debug('Querying program entries for organization: $organizationId');
      AppLogger.debug('Years being queried: $currentYear, $lastYear');

      // Create a stream for each category and year
      final streams = <Stream<List<ProgramEntry>>>[];

      for (final year in [currentYear, lastYear]) {
        for (final category in Form1728PCategory.values) {
          final path = 'organizations/$organizationId/program_entries/$year/${category.name}';
          AppLogger.debug('Creating stream for path: $path');
          
          final stream = _firestore
              .collection('organizations')
              .doc(organizationId)
              .collection('program_entries')
              .doc(year)
              .collection(category.name)
              .orderBy('lastUpdated', descending: true)
              .snapshots()
              .map((snapshot) {
                AppLogger.debug('Received snapshot for $path: ${snapshot.docs.length} documents');
                final entries = <ProgramEntry>[];
                
                for (final doc in snapshot.docs) {
                  try {
                    final data = doc.data();
                    AppLogger.debug('Processing document data: $data');
                    final programEntries = (data['entries'] as List<dynamic>?) ?? [];
                    AppLogger.debug('Processing document ${doc.id} with ${programEntries.length} entries');
                    
                    for (final entry in programEntries) {
                      try {
                        entries.add(ProgramEntry(
                          id: entry['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
                          date: DateTime.parse(entry['date'] as String),
                          category: category,
                          program: Form1728PProgram(
                            id: data['programId']?.toString() ?? '',
                            name: data['programName']?.toString() ?? 'Unknown Program',
                          ),
                          hours: entry['hours'] as int? ?? 0,
                          disbursement: (entry['disbursement'] as num?)?.toDouble() ?? 0.0,
                          description: entry['description']?.toString() ?? '',
                        ));
                      } catch (e) {
                        AppLogger.error('Error processing entry in document ${doc.id}: $e');
                        AppLogger.debug('Entry data causing error: $entry');
                      }
                    }
                  } catch (e) {
                    AppLogger.error('Error processing document ${doc.id}: $e');
                  }
                }
                return entries;
              });
          streams.add(stream);
        }
      }

      // Combine all streams into one
      return Rx.combineLatestList(streams).map((lists) {
        final allEntries = lists.expand((list) => list).toList();
        allEntries.sort((a, b) => b.date.compareTo(a.date));
        AppLogger.debug('Combined all streams: ${allEntries.length} total entries');
        return allEntries;
      });
    } catch (e) {
      AppLogger.error('Error in getProgramEntries: $e');
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

  Future<void> deleteProgramEntry({
    required String organizationId,
    required Form1728PCategory category,
    required String programId,
    String? year,
  }) async {
    try {
      final yearStr = year ?? DateTime.now().year.toString();
      final docRef = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('program_entries')
          .doc(yearStr)
          .collection(category.name)
          .doc(programId);
      await docRef.delete();
      AppLogger.debug('Deleted program entry: $organizationId, $category, $programId, $yearStr');
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting program entry', e, stackTrace);
      rethrow;
    }
  }
} 