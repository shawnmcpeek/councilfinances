import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hours_entry.dart';
import '../utils/logger.dart';
import '../services/auth_service.dart';

class MockHoursService {
  final AuthService _authService = AuthService();
  List<HoursEntry> _mockEntries = [];
  bool _isInitialized = false;

  // Singleton pattern
  static final MockHoursService _instance = MockHoursService._internal();
  factory MockHoursService() => _instance;
  MockHoursService._internal();

  String _formatOrganizationId(String organizationId, bool isAssembly) {
    if (organizationId.isEmpty) return '';
    if (organizationId.startsWith('C') || organizationId.startsWith('A')) return organizationId;
    
    final prefix = isAssembly ? 'A' : 'C';
    return '$prefix${organizationId.padLeft(6, '0')}';
  }

  Future<void> _initializeMockData() async {
    if (_isInitialized) return;
    
    try {
      AppLogger.info('Initializing mock hours data');
      
      // Create some sample mock hours data
      _mockEntries = [
        HoursEntry(
          id: '1',
          userId: 'mock-user-1',
          organizationId: 'C015857',
          isAssembly: false,
          programId: 'program-1',
          programName: 'Parish Breakfast',
          category: HoursCategory.community,
          startTime: Timestamp.fromDate(DateTime(2025, 1, 15, 8, 0)),
          endTime: Timestamp.fromDate(DateTime(2025, 1, 15, 12, 0)),
          totalHours: 4.0,
          description: 'Helped with breakfast setup and cleanup',
          disbursement: 0.0,
          createdAt: DateTime.now(),
        ),
        HoursEntry(
          id: '2',
          userId: 'mock-user-1',
          organizationId: 'C015857',
          isAssembly: false,
          programId: 'program-2',
          programName: 'Fish Fry',
          category: HoursCategory.community,
          startTime: Timestamp.fromDate(DateTime(2025, 1, 20, 16, 0)),
          endTime: Timestamp.fromDate(DateTime(2025, 1, 20, 22, 0)),
          totalHours: 6.0,
          description: 'Cooking and serving',
          disbursement: 0.0,
          createdAt: DateTime.now(),
        ),
        HoursEntry(
          id: '3',
          userId: 'mock-user-1',
          organizationId: 'C015857',
          isAssembly: false,
          programId: 'program-3',
          programName: 'Movie Night',
          category: HoursCategory.family,
          startTime: Timestamp.fromDate(DateTime(2025, 1, 25, 18, 0)),
          endTime: Timestamp.fromDate(DateTime(2025, 1, 25, 21, 0)),
          totalHours: 3.0,
          description: 'Setup and supervision',
          disbursement: 0.0,
          createdAt: DateTime.now(),
        ),
        HoursEntry(
          id: '4',
          userId: 'mock-user-1',
          organizationId: 'C015857',
          isAssembly: false,
          programId: 'program-4',
          programName: 'Seminarian Appreciation',
          category: HoursCategory.faith,
          startTime: Timestamp.fromDate(DateTime(2025, 2, 1, 17, 0)),
          endTime: Timestamp.fromDate(DateTime(2025, 2, 1, 20, 0)),
          totalHours: 3.0,
          description: 'Meal preparation and hosting',
          disbursement: 0.0,
          createdAt: DateTime.now(),
        ),
        HoursEntry(
          id: '5',
          userId: 'mock-user-1',
          organizationId: 'C015857',
          isAssembly: false,
          programId: 'program-5',
          programName: 'St. Martin Supplies',
          category: HoursCategory.faith,
          startTime: Timestamp.fromDate(DateTime(2025, 2, 5, 14, 0)),
          endTime: Timestamp.fromDate(DateTime(2025, 2, 5, 16, 0)),
          totalHours: 2.0,
          description: 'Organizing and delivering supplies',
          disbursement: 0.0,
          createdAt: DateTime.now(),
        ),
      ];
      
      _isInitialized = true;
      AppLogger.info('Mock hours data initialized with ${_mockEntries.length} entries');
    } catch (e, stackTrace) {
      AppLogger.error('Error initializing mock hours data', e, stackTrace);
      rethrow;
    }
  }

  Future<void> addHoursEntry(HoursEntry entry, bool isAssembly) async {
    try {
      await _initializeMockData();
      
      final user = _authService.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      final formattedOrgId = _formatOrganizationId(entry.organizationId, isAssembly);
      
      final newEntry = HoursEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        organizationId: formattedOrgId,
        isAssembly: isAssembly,
        programId: entry.programId,
        programName: entry.programName,
        category: entry.category,
        startTime: entry.startTime,
        endTime: entry.endTime,
        totalHours: entry.totalHours,
        description: entry.description,
        disbursement: entry.disbursement,
        createdAt: DateTime.now(),
      );

      _mockEntries.add(newEntry);
      AppLogger.debug('Added mock hours entry: ${newEntry.programName} - ${newEntry.totalHours} hours');
    } catch (e) {
      AppLogger.error('Error adding mock hours entry', e);
      rethrow;
    }
  }

  Future<void> updateHoursEntry(HoursEntry entry, bool isAssembly) async {
    try {
      await _initializeMockData();
      
      final user = _authService.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      final formattedOrgId = _formatOrganizationId(entry.organizationId, isAssembly);
      
      final index = _mockEntries.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        _mockEntries[index] = HoursEntry(
          id: entry.id,
          userId: user.uid,
          organizationId: formattedOrgId,
          isAssembly: isAssembly,
          programId: entry.programId,
          programName: entry.programName,
          category: entry.category,
          startTime: entry.startTime,
          endTime: entry.endTime,
          totalHours: entry.totalHours,
          description: entry.description,
          disbursement: entry.disbursement,
          createdAt: DateTime.now(),
        );
        AppLogger.debug('Updated mock hours entry: ${entry.id}');
      } else {
        throw Exception('Entry not found: ${entry.id}');
      }
    } catch (e) {
      AppLogger.error('Error updating mock hours entry', e);
      rethrow;
    }
  }

  Future<void> deleteHoursEntry(String organizationId, String entryId, bool isAssembly) async {
    try {
      await _initializeMockData();
      
      final user = _authService.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      final index = _mockEntries.indexWhere((e) => e.id == entryId);
      if (index != -1) {
        final entry = _mockEntries.removeAt(index);
        AppLogger.debug('Deleted mock hours entry: ${entry.id}');
      } else {
        throw Exception('Entry not found: $entryId');
      }
    } catch (e) {
      AppLogger.error('Error deleting mock hours entry', e);
      rethrow;
    }
  }

  Stream<List<HoursEntry>> getHoursEntries(String organizationId, bool isAssembly) {
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      final formattedOrgId = _formatOrganizationId(organizationId, isAssembly);
      AppLogger.debug('Getting mock hours entries for organization: $formattedOrgId and user: ${user.uid}');
      
      // Return a stream that emits the filtered entries
      return Stream.fromFuture(_getFilteredEntries(formattedOrgId, user.uid));
    } catch (e) {
      AppLogger.error('Error getting mock hours entries', e);
      rethrow;
    }
  }

  Future<List<HoursEntry>> _getFilteredEntries(String formattedOrgId, String userId) async {
    await _initializeMockData();
    
    final filteredEntries = _mockEntries
        .where((entry) => entry.organizationId == formattedOrgId && entry.userId == userId)
        .toList();
    
    // Sort by start time (newest first)
    filteredEntries.sort((a, b) => b.startTime.compareTo(a.startTime));
    
    AppLogger.debug('Returning ${filteredEntries.length} mock hours entries');
    return filteredEntries;
  }

  Future<List<HoursEntry>> getHoursEntriesByYear(
    String organizationId,
    bool isAssembly,
    int year,
  ) async {
    try {
      await _initializeMockData();
      
      final user = _authService.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      final formattedOrgId = _formatOrganizationId(organizationId, isAssembly);
      final startOfYear = DateTime(year);
      final endOfYear = DateTime(year + 1);
      
      final filteredEntries = _mockEntries.where((entry) {
        return entry.organizationId == formattedOrgId &&
               entry.userId == user.uid &&
               entry.startTime.toDate().isAfter(startOfYear) &&
               entry.startTime.toDate().isBefore(endOfYear);
      }).toList();
      
      // Sort by start time (newest first)
      filteredEntries.sort((a, b) => b.startTime.compareTo(a.startTime));
      
      AppLogger.debug('Returning ${filteredEntries.length} mock hours entries for year $year');
      return filteredEntries;
    } catch (e) {
      AppLogger.error('Error getting mock hours entries by year', e);
      rethrow;
    }
  }

  // Method to clear mock data (useful for testing)
  void clearMockData() {
    _mockEntries.clear();
    _isInitialized = false;
    AppLogger.info('Mock hours data cleared');
  }

  // Method to add custom mock entries (useful for testing)
  void addMockEntry(HoursEntry entry) {
    _mockEntries.add(entry);
    AppLogger.info('Added custom mock hours entry: ${entry.id}');
  }
} 