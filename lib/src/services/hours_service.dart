import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';
import '../models/hours_entry.dart';
import 'auth_service.dart';

class HoursService {
  final SupabaseClient _supabase = Supabase.instance.client;
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

  // Add a new hours entry
  Future<void> addHoursEntry(HoursEntry entry) async {
    try {
      final entryData = {
        'id': entry.id,
        'user_id': entry.userId,
        'organization_id': entry.organizationId,
        'program_id': entry.programId,
        'program_name': entry.programName,
        'category': entry.category,
        'start_time': entry.startTime.toIso8601String(),
        'end_time': entry.endTime.toIso8601String(),
        'total_hours': entry.totalHours,
        'disbursement': entry.disbursement,
        'description': entry.description,
      };

      await _supabase
          .from('hours_entries')
          .insert(entryData);
      AppLogger.debug('Added hours entry: ${entry.id}');
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
      final data = {
        'organization_id': formattedOrgId,
        'is_assembly': isAssembly,
        'program_id': entry.programId,
        'program_name': entry.programName,
        'category': entry.category.name,
        'start_time': entry.startTime.toIso8601String(),
        'end_time': entry.endTime.toIso8601String(),
        'total_hours': entry.totalHours,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add optional fields only if they have values
      if (entry.disbursement != null) {
        data['disbursement'] = entry.disbursement as Object;
      }
      if (entry.description?.isNotEmpty == true) {
        data['description'] = entry.description as Object;
      }

      AppLogger.debug('Updating hours entry: $data');
      await _supabase
          .from('hours_entries')
          .update(data)
          .eq('id', entry.id);
    } catch (e) {
      AppLogger.error('Error updating hours entry', e);
      rethrow;
    }
  }

  Future<void> deleteHoursEntry(String organizationId, String entryId) async {
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      AppLogger.debug('Deleting hours entry: $entryId');
      await _supabase
          .from('hours_entries')
          .delete()
          .eq('id', entryId);
    } catch (e) {
      AppLogger.error('Error deleting hours entry', e);
      rethrow;
    }
  }

  // Get hours entries for a specific organization
  Future<List<HoursEntry>> getHoursEntries(String organizationId) async {
    try {
      final response = await _supabase
          .from('hours_entries')
          .select('*')
          .eq('organization_id', organizationId)
          .order('created_at', ascending: false);

      return response.map((data) => HoursEntry.fromMap(data)).toList();
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
      final startOfYear = DateTime(year).toIso8601String();
      final endOfYear = DateTime(year + 1).toIso8601String();

      final response = await _supabase
          .from('hours_entries')
          .select()
          .eq('organization_id', formattedOrgId)
          .eq('user_id', user.id)
          .gte('start_time', startOfYear)
          .lt('start_time', endOfYear)
          .order('start_time', ascending: false);

      return response
          .map((data) => HoursEntry.fromMap(data))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting hours entries for year $year', e);
      rethrow;
    }
  }

  // Delete all hours entries for the current user
  Future<void> deleteUserHours() async {
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      AppLogger.debug('Deleting all hours entries for user: ${user.id}');
      await _supabase
          .from('hours_entries')
          .delete()
          .eq('user_id', user.id);
    } catch (e) {
      AppLogger.error('Error deleting user hours', e);
      throw Exception('Failed to delete user hours: ${e.toString()}');
    }
  }
} 