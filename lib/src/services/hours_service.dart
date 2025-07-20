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

  Future<void> addHoursEntry(HoursEntry entry, bool isAssembly) async {
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      final formattedOrgId = _formatOrganizationId(entry.organizationId, isAssembly);
      final data = {
        'userId': user.id,
        'organizationId': formattedOrgId,
        'isAssembly': isAssembly,
        'programId': entry.programId,
        'programName': entry.programName,
        'category': entry.category.name,
        'startTime': entry.startTime.toIso8601String(),
        'endTime': entry.endTime.toIso8601String(),
        'totalHours': entry.totalHours,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Add optional fields only if they have values
      if (entry.disbursement != null) {
        data['disbursement'] = entry.disbursement;
      }
      if (entry.description?.isNotEmpty == true) {
        data['description'] = entry.description;
      }

      AppLogger.debug('Adding hours entry: $data');
      await _supabase
          .from('hours')
          .insert(data);
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
        'organizationId': formattedOrgId,
        'isAssembly': isAssembly,
        'programId': entry.programId,
        'programName': entry.programName,
        'category': entry.category.name,
        'startTime': entry.startTime.toIso8601String(),
        'endTime': entry.endTime.toIso8601String(),
        'totalHours': entry.totalHours,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Add optional fields only if they have values
      if (entry.disbursement != null) {
        data['disbursement'] = entry.disbursement;
      }
      if (entry.description?.isNotEmpty == true) {
        data['description'] = entry.description;
      }

      AppLogger.debug('Updating hours entry: $data');
      await _supabase
          .from('hours')
          .update(data)
          .eq('id', entry.id);
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
      await _supabase
          .from('hours')
          .delete()
          .eq('id', entryId);
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
      AppLogger.debug('Getting hours entries for organization: $formattedOrgId and user: ${user.id}');
      
      return _supabase
          .from('hours')
          .stream(primaryKey: ['id'])
          .eq('organizationId', formattedOrgId)
          .eq('userId', user.id)
          .order('startTime', ascending: false)
          .limit(20)
          .map((response) {
            AppLogger.debug('Received ${response.length} hours entries from Supabase');
            return response
                .map((data) => HoursEntry.fromMap(data))
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
      final startOfYear = DateTime(year).toIso8601String();
      final endOfYear = DateTime(year + 1).toIso8601String();

      final response = await _supabase
          .from('hours')
          .select()
          .eq('organizationId', formattedOrgId)
          .eq('userId', user.id)
          .gte('startTime', startOfYear)
          .lt('startTime', endOfYear)
          .order('startTime', ascending: false);

      return response
          .map((data) => HoursEntry.fromMap(data))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting hours entries for year $year', e);
      rethrow;
    }
  }
} 