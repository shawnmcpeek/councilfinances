import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class OrganizationData {
  final String id;
  final String name;
  final String type;
  final String? city;
  final String? state;
  final String? jurisdiction;

  OrganizationData({
    required this.id,
    required this.name,
    required this.type,
    this.city,
    this.state,
    this.jurisdiction,
  });

  factory OrganizationData.fromMap(Map<String, dynamic> map) {
    return OrganizationData(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      city: map['city'] as String?,
      state: map['state'] as String?,
      jurisdiction: map['jurisdiction'] as String?,
    );
  }
}

class OrganizationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch organization data by council or assembly number
  Future<OrganizationData?> getOrganizationByNumber(int number, bool isAssembly) async {
    try {
      final organizationId = isAssembly 
          ? 'A${number.toString().padLeft(6, '0')}'
          : 'C${number.toString().padLeft(6, '0')}';

      AppLogger.debug('Fetching organization data for: $organizationId');

      final response = await _supabase
          .from('organizations')
          .select('*')
          .eq('id', organizationId)
          .single();

      return OrganizationData.fromMap(response);
    } catch (e) {
      if (e is PostgrestException && e.code == 'PGRST116') {
        // No organization found with this number
        AppLogger.debug('No organization found for number: $number (${isAssembly ? 'Assembly' : 'Council'})');
        return null;
      }
      AppLogger.error('Error fetching organization data', e);
      return null;
    }
  }

  /// Create or update organization with location data
  Future<void> upsertOrganization({
    required int number,
    required bool isAssembly,
    required String name,
    String? city,
    String? state,
    String? jurisdiction,
  }) async {
    try {
      final organizationId = isAssembly 
          ? 'A${number.toString().padLeft(6, '0')}'
          : 'C${number.toString().padLeft(6, '0')}';

      final data = {
        'id': organizationId,
        'name': name,
        'type': isAssembly ? 'assembly' : 'council',
        'city': city,
        'state': state,
        'jurisdiction': jurisdiction,
      };

      AppLogger.debug('Upserting organization: $data');

      await _supabase
          .from('organizations')
          .upsert(data)
          .eq('id', organizationId);
    } catch (e) {
      AppLogger.error('Error upserting organization', e);
      rethrow;
    }
  }
} 