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
      
      // Debug logging to see what's loaded
      AppLogger.debug('Council programs keys: ${programsData.councilPrograms.keys.toList()}');
      AppLogger.debug('Assembly programs keys: ${programsData.assemblyPrograms.keys.toList()}');
      
      return programsData;
    } catch (e, stackTrace) {
      AppLogger.error('Error loading system programs', e, stackTrace);
      rethrow;
    }
  }

  // Load program states for a specific organization
  Future<void> loadProgramStates(ProgramsData programsData, String organizationId) async {
    try {
      AppLogger.debug('Loading program states for organization: $organizationId');
      
      // Get all programs for this organization
      final response = await _supabase
          .from('programs')
          .select('*')
          .eq('organization_id', organizationId);

      // Create a map of program states
      final Map<String, bool> programStates = {};
      for (var data in response) {
        programStates[data['id']] = data['is_enabled'] ?? true;
      }

      // Determine if this is assembly or council based on organization ID prefix
      final isAssembly = organizationId.startsWith('A');
      final programs = isAssembly ? programsData.assemblyPrograms : programsData.councilPrograms;
      
      // Update program states
      for (var categoryPrograms in programs.values) {
        for (var program in categoryPrograms) {
          program.isEnabled = programStates[program.id] ?? true;
        }
      }
    } catch (e) {
      AppLogger.error('Error loading program states', e);
      rethrow;
    }
  }

  // Get custom programs for a specific organization
  Future<List<Program>> getCustomPrograms(String organizationId) async {
    try {
      AppLogger.debug('getCustomPrograms: orgId=$organizationId');
      
      // Ensure organization ID is properly formatted
      String formattedOrgId = organizationId;
      if (!organizationId.startsWith('C') && !organizationId.startsWith('A')) {
        // This shouldn't happen in normal flow, but handle it gracefully
        AppLogger.debug('getCustomPrograms: invalid orgId format, using as-is: $organizationId');
      }
      
      // Get custom programs from the programs table where is_system_default = false
      final response = await _supabase
          .from('programs')
          .select('*')
          .eq('organization_id', formattedOrgId)
          .eq('is_system_default', false);

      AppLogger.debug('getCustomPrograms: programs response length=${response.length}');
      AppLogger.debug('getCustomPrograms: programs response=$response');

      // Convert to Program objects
      final List<Program> customPrograms = [];
      
      for (var data in response) {
        final program = Program.fromMap({
          'id': data['id'],
          'name': data['name'],
          'category': data['category'],
          'isSystemDefault': data['is_system_default'] ?? false,
          'financialType': data['financial_type'] ?? FinancialType.both.name,
          'isEnabled': data['is_enabled'] ?? true,
        });
        customPrograms.add(program);
        AppLogger.debug('getCustomPrograms: added custom program: ${data['name']}');
      }

      AppLogger.debug('getCustomPrograms: parsed custom programs: ${customPrograms.map((p) => '${p.name} (${p.id})').toList()}');
      
      return customPrograms;
    } catch (e) {
      AppLogger.error('Error getting custom programs', e);
      rethrow;
    }
  }

  // Add a custom program
  Future<void> addCustomProgram(String organizationId, Program program) async {
    try {
      // Generate a unique ID for the program
      final programId = '${organizationId}_${DateTime.now().millisecondsSinceEpoch}';
      
      final programData = {
        'id': programId,
        'name': program.name,
        'category': program.category.toUpperCase(), // Ensure category is uppercase
        'is_system_default': false,
        'financial_type': program.financialType.name,
        'is_enabled': true,
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
  Future<void> updateProgramStates(String organizationId, Map<String, bool> states, {ProgramsData? programsData}) async {
    try {
      AppLogger.debug('Updating program states for organization: $organizationId');
      for (final entry in states.entries) {
        final programId = entry.key;
        final isEnabled = entry.value;
        // Try to find the program in system programs if programsData is provided
        Program? systemProgram;
        if (programsData != null) {
          final isAssembly = organizationId.startsWith('A');
          final programsMap = isAssembly ? programsData.assemblyPrograms : programsData.councilPrograms;
          for (var categoryPrograms in programsMap.values) {
            for (var program in categoryPrograms) {
              if (program.id == programId) {
                systemProgram = program;
                break;
              }
            }
            if (systemProgram != null) break;
          }
        }
        final upsertData = {
          'id': programId,
          'organization_id': organizationId,
          'is_enabled': isEnabled,
        };
        if (systemProgram != null) {
          upsertData['name'] = systemProgram.name;
          upsertData['category'] = systemProgram.category;
          upsertData['is_system_default'] = true;
          upsertData['financial_type'] = systemProgram.financialType.name;
        }
        await _supabase
            .from('programs')
            .upsert(upsertData);
        AppLogger.debug('Upserted program $programId with is_enabled=$isEnabled');
      }
      // Fetch and log all programs for the org after upsert
      final allPrograms = await _supabase
          .from('programs')
          .select()
          .eq('organization_id', organizationId);
      AppLogger.debug('All programs for org $organizationId after upsert: $allPrograms');
    } catch (e) {
      AppLogger.error('Error updating program states', e);
      rethrow;
    }
  }

  // Update a single program (handles both system and custom programs)
  Future<void> updateCustomProgram(String organizationId, Program program) async {
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
  Future<void> deleteCustomProgram(String organizationId, String programId) async {
    try {
      await _supabase
          .from('programs')
          .delete()
          .eq('id', programId)
          .eq('organization_id', organizationId);
      AppLogger.debug('Deleted custom program: $programId');
    } catch (e) {
      AppLogger.error('Error deleting custom program', e);
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