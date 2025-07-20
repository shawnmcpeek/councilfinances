import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/program.dart';
import '../utils/logger.dart';

class ProgramService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _systemProgramsPath = 'assets/data/system_programs.json';

  // Load system default programs from JSON asset
  Future<ProgramsData> loadSystemPrograms() async {
    try {
      AppLogger.info('Loading system programs from $_systemProgramsPath');
      final String jsonString = await rootBundle.loadString(_systemProgramsPath);
      AppLogger.info('Successfully loaded JSON string from asset');
      
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      AppLogger.info('Successfully decoded JSON data');
      
      final programsData = ProgramsData.fromJson(jsonData);
      AppLogger.info('Successfully parsed ProgramsData from JSON');
      
      return programsData;
    } catch (e, stackTrace) {
      AppLogger.error('Error loading system programs', e, stackTrace);
      rethrow;
    }
  }

  // Load program states for a specific organization
  Future<void> loadProgramStates(ProgramsData programsData, String organizationId, bool isAssembly) async {
    try {
      if (organizationId.isEmpty) {
        AppLogger.error('Cannot load program states: organizationId is empty');
        return;
      }

      AppLogger.debug('Loading program states for organization: $organizationId');
      
      // Ensure organization ID is properly formatted
      if (!organizationId.startsWith('C') && !organizationId.startsWith('A')) {
        organizationId = isAssembly 
            ? 'A${organizationId.padLeft(6, '0')}'
            : 'C${organizationId.padLeft(6, '0')}';
      }

      final response = await _supabase
          .from('programs')
          .select()
          .eq('organization_id', organizationId);

      // Reset all programs to enabled by default
      final programs = isAssembly ? programsData.assemblyPrograms : programsData.councilPrograms;
      for (var categoryPrograms in programs.values) {
        for (var program in categoryPrograms) {
          program.isEnabled = true;
          program.financialType = FinancialType.both; // Set default financial type
        }
      }

      // Apply stored states from programs table
      for (var data in response) {
        final programId = data['id'] as String;
        final isEnabled = data['is_enabled'] as bool? ?? true;
        final financialTypeStr = data['financial_type'] as String? ?? 'both';

        for (var categoryPrograms in programs.values) {
          for (var program in categoryPrograms) {
            if (program.id == programId) {
              program.isEnabled = isEnabled;
              program.financialType = FinancialType.values.firstWhere(
                (type) => type.name == financialTypeStr,
                orElse: () => FinancialType.both
              );
              break;
            }
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading program states', e, stackTrace);
      // Don't rethrow, just log the error and continue with default states
      AppLogger.info('Continuing with default program states');
    }
  }

  // Get custom programs for a specific organization
  Future<List<Program>> getCustomPrograms(String organizationId, bool isAssembly) async {
    try {
      AppLogger.debug('getCustomPrograms: orgId=$organizationId, isAssembly=$isAssembly');
      
      final response = await _supabase
          .from('programs')
          .select()
          .eq('organization_id', organizationId)
          .eq('is_assembly', isAssembly)
          .eq('is_system_default', false);

      AppLogger.debug('getCustomPrograms: raw response length=${response.length}');
      AppLogger.debug('getCustomPrograms: raw response=$response');

      return response.map((data) {
        return Program.fromMap({
          'id': data['id'],
          'name': data['name'],
          'category': data['category'],
          'isSystemDefault': data['is_system_default'] ?? false,
          'financialType': data['financial_type'] ?? FinancialType.both.name,
          'isEnabled': data['is_enabled'] ?? true,
        });
      }).toList();
    } catch (e) {
      AppLogger.error('Error getting custom programs', e);
      rethrow;
    }
  }

  // Add a custom program
  Future<void> addCustomProgram(String organizationId, Program program, bool isAssembly) async {
    try {
      // Generate a unique ID for the program
      final programId = '${organizationId}_${DateTime.now().millisecondsSinceEpoch}';
      
      final programData = {
        'id': programId,
        'name': program.name,
        'category': program.category,
        'is_system_default': false,
        'financial_type': program.financialType.name,
        'is_enabled': true,
        'is_assembly': isAssembly,
        'organization_id': organizationId,
      };

      await _supabase
          .from('programs')
          .insert(programData);
      AppLogger.debug('Added custom program: ${program.name} with ID: $programId and financial type: ${program.financialType.name}');
    } catch (e) {
      AppLogger.error('Error adding custom program', e);
      rethrow;
    }
  }

  // Update all program states at once
  Future<void> updateProgramStates(String organizationId, Map<String, dynamic> states) async {
    try {
      // This method would need to be updated to work with individual program records
      // For now, we'll just log that it's not implemented
      AppLogger.debug('updateProgramStates not implemented for programs table structure');
    } catch (e) {
      AppLogger.error('Error updating program states', e);
      rethrow;
    }
  }

  // Update a single program (handles both system and custom programs)
  Future<void> updateCustomProgram(String organizationId, Program program, bool isAssembly) async {
    try {
      final programData = {
        'name': program.name,
        'category': program.category,
        'financial_type': program.financialType.name,
        'is_enabled': program.isEnabled,
      };

      await _supabase
          .from('programs')
          .update(programData)
          .eq('id', program.id);
      AppLogger.debug('Updated custom program: ${program.name} with financial type: ${program.financialType.name}');
    } catch (e) {
      AppLogger.error('Error updating custom program', e);
      rethrow;
    }
  }

  // Delete a custom program
  Future<void> deleteCustomProgram(String organizationId, String programId, bool isAssembly) async {
    try {
      // Ensure organization ID is properly formatted
      if (!organizationId.startsWith('C') && !organizationId.startsWith('A')) {
        organizationId = isAssembly 
            ? 'A${organizationId.padLeft(6, '0')}'
            : 'C${organizationId.padLeft(6, '0')}';
      }

      await _supabase
          .from('programs')
          .delete()
          .eq('id', programId);
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting program', e, stackTrace);
      rethrow;
    }
  }

  // Add this new method
  Future<void> updateProgramFinancialType(String organizationId, String programId, FinancialType type) async {
    try {
      await _supabase
          .from('programs')
          .update({
            'financial_type': type.name,
          })
          .eq('id', programId);
      
      AppLogger.debug('Updated program financial type: $programId to ${type.name}');
    } catch (e) {
      AppLogger.error('Error updating program financial type', e);
      rethrow;
    }
  }
}