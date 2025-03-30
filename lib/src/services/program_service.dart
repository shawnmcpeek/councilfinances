import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/program.dart';
import '../utils/logger.dart';

class ProgramService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
      AppLogger.debug('Loading program states for organization: $organizationId');
      
      // Ensure organization ID is properly formatted
      if (!organizationId.startsWith('C') && !organizationId.startsWith('A')) {
        organizationId = isAssembly 
            ? 'A${organizationId.padLeft(6, '0')}'
            : 'C${organizationId.padLeft(6, '0')}';
      }

      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('program_states')
          .doc('states')
          .get();

      AppLogger.debug('Program states document exists: ${doc.exists}');

      // Reset all programs to enabled by default
      final programs = isAssembly ? programsData.assemblyPrograms : programsData.councilPrograms;
      for (var categoryPrograms in programs.values) {
        for (var program in categoryPrograms) {
          program.isEnabled = true;
        }
      }

      // Apply stored states if the document exists
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        AppLogger.debug('Loaded program states: $data');
        
        for (var entry in data.entries) {
          if (entry.key == 'updatedAt') continue; // Skip timestamp field
          
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
      } else {
        AppLogger.debug('No program states found, using defaults');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading program states', e, stackTrace);
      rethrow; // Rethrow to handle the error in the UI
    }
  }

  // Get custom programs for a specific organization
  Future<List<Program>> getCustomPrograms(String organizationId, bool isAssembly) async {
    try {
      // Ensure organization ID is properly formatted
      if (!organizationId.startsWith('C') && !organizationId.startsWith('A')) {
        organizationId = isAssembly 
            ? 'A${organizationId.padLeft(6, '0')}'
            : 'C${organizationId.padLeft(6, '0')}';
      }

      AppLogger.debug('Loading custom programs for organization: $organizationId');
      
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('custom_programs')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Program.fromJson(data);
      }).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error loading custom programs', e, stackTrace);
      return [];
    }
  }

  // Add a custom program
  Future<void> addCustomProgram(String organizationId, Program program, bool isAssembly) async {
    await _firestore
        .collection('programs')
        .doc(organizationId)
        .collection('custom')
        .add({
          ...program.toJson(),
          'createdAt': FieldValue.serverTimestamp(),
          'isEnabled': true,
        });
  }

  // Update all program states at once
  Future<void> updateProgramStates(String organizationId, Map<String, bool> programStates) async {
    try {
      // Ensure organization ID is properly formatted
      if (!organizationId.startsWith('C') && !organizationId.startsWith('A')) {
        throw Exception('Invalid organization ID format: $organizationId');
      }

      AppLogger.debug('Updating program states for organization: $organizationId');
      AppLogger.debug('States to update: $programStates');

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('program_states')
          .doc('states')
          .set({
            ...programStates,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e, stackTrace) {
      AppLogger.error('Error updating program states', e, stackTrace);
      rethrow;
    }
  }

  // Update a single program (handles both system and custom programs)
  Future<void> updateCustomProgram(String organizationId, Program program, bool isAssembly) async {
    try {
      // Ensure organization ID is properly formatted
      if (!organizationId.startsWith('C') && !organizationId.startsWith('A')) {
        organizationId = isAssembly 
            ? 'A${organizationId.padLeft(6, '0')}'
            : 'C${organizationId.padLeft(6, '0')}';
      }

      if (program.isSystemDefault) {
        // For system programs, update the states document
        await _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('program_states')
            .doc('states')
            .set({
              program.id: program.isEnabled,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      } else {
        // For custom programs, update the full document
        await _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('custom_programs')
            .doc(program.id)
            .update({
              ...program.toJson(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error updating program', e, stackTrace);
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

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('custom_programs')
          .doc(programId)
          .delete();
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting program', e, stackTrace);
      rethrow;
    }
  }
} 