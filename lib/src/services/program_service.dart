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
          .from('program_states')
          .select()
          .eq('organizationId', organizationId)
          .single();

      // Reset all programs to enabled by default
      final programs = isAssembly ? programsData.assemblyPrograms : programsData.councilPrograms;
      for (var categoryPrograms in programs.values) {
        for (var program in categoryPrograms) {
          program.isEnabled = true;
          program.financialType = FinancialType.both; // Set default financial type
        }
      }

      // Apply stored states since we have a response from .single()
      // Handle program states
      final states = response['states'] as Map<String, dynamic>?;
      if (states != null) {
        for (var entry in states.entries) {
          final programId = entry.key;
          final isEnabled = entry.value as bool;

          for (var categoryPrograms in programs.values) {
            for (var program in categoryPrograms) {
              if (program.id == programId) {
                program.isEnabled = isEnabled;
                break;
              }
            }
          }
        }
      }

      // Handle financial types
      final financialTypes = response['financialTypes'] as Map<String, dynamic>?;
      if (financialTypes != null) {
        for (var entry in financialTypes.entries) {
          final programId = entry.key;
          final typeStr = entry.value as String;

          for (var categoryPrograms in programs.values) {
            for (var program in categoryPrograms) {
              if (program.id == programId) {
                program.financialType = FinancialType.values.firstWhere(
                  (type) => type.name == typeStr,
                  orElse: () => FinancialType.both
                );
                break;
              }
            }
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading program states', e, stackTrace);
      // Don't rethrow, just log the error and continue with default states
      AppLogger.info('Continuing with default program states - creating default states document');
      
      try {
        // Create default states document when no existing document is found
        await _supabase
          .from('program_states')
          .insert({
            'organizationId': organizationId,
            'states': {},
            'financialTypes': {},
            'createdAt': DateTime.now().toIso8601String(),
          });
      } catch (insertError) {
        AppLogger.error('Error creating default program states document', insertError);
      }
    }
  }

  // Get custom programs for a specific organization
  Future<List<Program>> getCustomPrograms(String organizationId, bool isAssembly) async {
    try {
      final response = await _supabase
          .from('custom_programs')
          .select()
          .eq('organizationId', organizationId)
          .eq('isAssembly', isAssembly);

      return response.map((data) {
        return Program.fromMap({
          'id': data['id'],
          'name': data['name'],
          'category': data['category'],
          'isSystemDefault': data['isSystemDefault'] ?? false,
          'financialType': data['financialType'] ?? FinancialType.both.name,
          'isEnabled': data['isEnabled'] ?? true,
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
      final programData = {
        'name': program.name,
        'category': program.category,
        'isSystemDefault': false,
        'financialType': program.financialType.name,
        'isEnabled': true,
        'isAssembly': isAssembly,
        'organizationId': organizationId,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('custom_programs')
          .insert(programData);
      AppLogger.debug('Added custom program: ${program.name} with financial type: ${program.financialType.name}');
    } catch (e) {
      AppLogger.error('Error adding custom program', e);
      rethrow;
    }
  }

  // Update all program states at once
  Future<void> updateProgramStates(String organizationId, Map<String, dynamic> states) async {
    try {
      await _supabase
          .from('program_states')
          .upsert({
            'organizationId': organizationId,
            'states': states,
            'updatedAt': DateTime.now().toIso8601String(),
          });
      
      AppLogger.debug('Updated program states: $states');
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
        'financialType': program.financialType.name,
        'isEnabled': program.isEnabled,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('custom_programs')
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
          .from('custom_programs')
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
          .from('program_states')
          .upsert({
            'organizationId': organizationId,
            'financialTypes': {
              programId: type.name,
            },
            'updatedAt': DateTime.now().toIso8601String(),
          });
      
      AppLogger.debug('Updated program financial type: $programId to ${type.name}');
    } catch (e) {
      AppLogger.error('Error updating program financial type', e);
      rethrow;
    }
  }
}