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

      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('programs')
          .doc('states')
          .get();

      AppLogger.debug('Program states document exists: ${doc.exists}');

      // Reset all programs to enabled by default
      final programs = isAssembly ? programsData.assemblyPrograms : programsData.councilPrograms;
      for (var categoryPrograms in programs.values) {
        for (var program in categoryPrograms) {
          program.isEnabled = true;
          program.financialType = FinancialType.both; // Set default financial type
        }
      }

      // Apply stored states if the document exists
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Handle program states
        final states = data['states'] as Map<String, dynamic>?;
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
        final financialTypes = data['financialTypes'] as Map<String, dynamic>?;
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
      } else {
        AppLogger.debug('No program states found, using defaults');
        // Create default states document
        await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('programs')
          .doc('states')
          .set({
            'states': {},
            'financialTypes': {},
            'createdAt': FieldValue.serverTimestamp(),
          });
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
      final snapshot = await _firestore.collection('organizations')
          .doc(organizationId)
          .collection('programs')
          .where('isAssembly', isEqualTo: isAssembly)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Program.fromMap({
          'id': doc.id,
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
      final docRef = _firestore.collection('organizations')
          .doc(organizationId)
          .collection('programs')
          .doc();

      final programData = {
        'id': docRef.id,
        'name': program.name,
        'category': program.category,
        'isSystemDefault': false,
        'financialType': program.financialType.name,
        'isEnabled': true,
        'isAssembly': isAssembly,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(programData);
      AppLogger.debug('Added custom program: ${program.name} with financial type: ${program.financialType.name}');
    } catch (e) {
      AppLogger.error('Error adding custom program', e);
      rethrow;
    }
  }

  // Update all program states at once
  Future<void> updateProgramStates(String organizationId, Map<String, dynamic> states) async {
    try {
      final docRef = _firestore.collection('organizations')
          .doc(organizationId)
          .collection('programs')
          .doc('states');

      AppLogger.debug('Attempting to write to Firestore path: \\${docRef.path}');
      AppLogger.debug('Data being written: \\${{
        'states': states,
        'updatedAt': FieldValue.serverTimestamp(),
      }}');

      await docRef.set({
        'states': states,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      AppLogger.debug('Successfully wrote to Firestore path: \\${docRef.path}');
    } catch (e, stackTrace) {
      AppLogger.error('Error updating program states at path: \\${_firestore.collection('organizations').doc(organizationId).collection('programs').doc('states').path}', e, stackTrace);
      rethrow;
    }
  }

  // Update a single program (handles both system and custom programs)
  Future<void> updateCustomProgram(String organizationId, Program program, bool isAssembly) async {
    try {
      final docRef = _firestore.collection('organizations')
          .doc(organizationId)
          .collection('programs')
          .doc(program.id);

      final programData = {
        'name': program.name,
        'category': program.category,
        'financialType': program.financialType.name,
        'isEnabled': program.isEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.update(programData);
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

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('programs')
          .doc(programId)
          .delete();
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting program', e, stackTrace);
      rethrow;
    }
  }

  Future<void> migrateExistingPrograms(String organizationId) async {
    try {
      final programsSnapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('programs')
          .get();

      final batch = _firestore.batch();

      for (var doc in programsSnapshot.docs) {
        final data = doc.data();
        if (!data.containsKey('financialType')) {
          batch.update(doc.reference, {
            'financialType': FinancialType.both.name,
          });
        }
      }

      await batch.commit();
      AppLogger.debug('Completed migration of existing programs for organization: $organizationId');
    } catch (e) {
      AppLogger.error('Error migrating existing programs', e);
      rethrow;
    }
  }

  // Add this new method
  Future<void> updateProgramFinancialType(String organizationId, String programId, FinancialType type) async {
    try {
      final docRef = _firestore.collection('organizations')
          .doc(organizationId)
          .collection('programs')
          .doc('states');

      await docRef.set({
        'financialTypes': {
          programId: type.name,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      AppLogger.debug('Updated program financial type: $programId to ${type.name}');
    } catch (e) {
      AppLogger.error('Error updating program financial type', e);
      rethrow;
    }
  }
} 