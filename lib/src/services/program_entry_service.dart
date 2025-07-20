import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/form1728p_program.dart';
import '../models/program_entry_adapter.dart';
import '../utils/logger.dart';

class ProgramEntryService {
  final SupabaseClient _supabase = Supabase.instance.client;

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
      
      // Check if entry exists
      final existingResponse = await _supabase
          .from('program_entries')
          .select()
          .eq('organization_id', organizationId)
          .eq('year', currentYear)
          .eq('category', category.name)
          .eq('program_id', program.id)
          .maybeSingle();

      if (existingResponse != null) {
        // Update existing entry by adding to the current values
        final existingHours = existingResponse['hours'] as int? ?? 0;
        final existingDisbursement = existingResponse['disbursement'] as double? ?? 0.0;
        final existingEntries = existingResponse['entries'] as List<dynamic>? ?? [];

        final newEntry = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'hours': hours,
          'disbursement': disbursement,
          'description': description,
          'date': date.toIso8601String(),
          'timestamp': DateTime.now().toIso8601String(),
        };

        existingEntries.add(newEntry);

        await _supabase
            .from('program_entries')
            .update({
              'hours': existingHours + hours,
              'disbursement': existingDisbursement + disbursement,
              'last_updated': DateTime.now().toIso8601String(),
              'entries': existingEntries,
            })
            .eq('id', existingResponse['id']);

        AppLogger.debug(
          'Updated program entry: ${program.name}, '
          'Total Hours: ${existingHours + hours}, '
          'Total Disbursement: ${existingDisbursement + disbursement}'
        );
      } else {
        // Create new entry
        final newEntry = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'hours': hours,
          'disbursement': disbursement,
          'description': description,
          'date': date.toIso8601String(),
          'timestamp': DateTime.now().toIso8601String(),
        };

        await _supabase
            .from('program_entries')
            .insert({
              'organization_id': organizationId,
              'year': currentYear,
              'category': category.name,
              'program_id': program.id,
              'program_name': program.name,
              'hours': hours,
              'disbursement': disbursement,
              'created': DateTime.now().toIso8601String(),
              'last_updated': DateTime.now().toIso8601String(),
              'entries': [newEntry],
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

      return _supabase
          .from('program_entries')
          .stream(primaryKey: ['id'])
          .eq('organization_id', organizationId)
          .order('last_updated', ascending: false)
          .map((response) {
            AppLogger.debug('Received ${response.length} program entries from Supabase');
            final entries = <ProgramEntry>[];
            
            for (final data in response) {
              try {
                final programEntries = (data['entries'] as List<dynamic>?) ?? [];
                final category = Form1728PCategory.values.firstWhere(
                  (c) => c.name == data['category'],
                  orElse: () => Form1728PCategory.faith,
                );
                
                for (final entry in programEntries) {
                  try {
                    entries.add(ProgramEntry(
                      id: entry['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      date: DateTime.parse(entry['date'] as String),
                      category: category,
                      program: Form1728PProgram(
                        id: data['program_id']?.toString() ?? '',
                        name: data['program_name']?.toString() ?? 'Unknown Program',
                      ),
                      hours: entry['hours'] as int? ?? 0,
                      disbursement: (entry['disbursement'] as num?)?.toDouble() ?? 0.0,
                      description: entry['description']?.toString() ?? '',
                    ));
                  } catch (e) {
                    AppLogger.error('Error processing entry: $e');
                    AppLogger.debug('Entry data causing error: $entry');
                  }
                }
              } catch (e) {
                AppLogger.error('Error processing program entry data: $e');
              }
            }
            
            entries.sort((a, b) => b.date.compareTo(a.date));
            AppLogger.debug('Processed ${entries.length} total entries');
            return entries;
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
      
      final response = await _supabase
          .from('program_entries')
          .select()
          .eq('organization_id', organizationId)
          .eq('year', yearStr)
          .eq('category', category.name)
          .eq('program_id', programId)
          .maybeSingle();

      return {
        'hours': response?['hours'] as int? ?? 0,
        'disbursement': response?['disbursement'] as double? ?? 0.0,
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
      await _supabase
          .from('program_entries')
          .delete()
          .eq('organization_id', organizationId)
          .eq('year', yearStr)
          .eq('category', category.name)
          .eq('program_id', programId);
      AppLogger.debug('Deleted program entry: $organizationId, $category, $programId, $yearStr');
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting program entry', e, stackTrace);
      rethrow;
    }
  }
}