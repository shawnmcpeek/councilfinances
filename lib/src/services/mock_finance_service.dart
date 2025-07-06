import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/finance_entry.dart';
import '../utils/logger.dart';
import '../models/payment_method.dart';
import '../models/program.dart';
import '../services/auth_service.dart';

class MockFinanceService {
  final AuthService _authService = AuthService();
  List<FinanceEntry> _mockEntries = [];
  bool _isInitialized = false;

  // Singleton pattern
  static final MockFinanceService _instance = MockFinanceService._internal();
  factory MockFinanceService() => _instance;
  MockFinanceService._internal();

  String _getFormattedOrgId(String organizationId, bool isAssembly) {
    // If the ID already starts with C or A, return it as is
    if (organizationId.startsWith('C') || organizationId.startsWith('A')) {
      return organizationId;
    }
    
    // Otherwise, add the prefix
    final orgPrefix = isAssembly ? 'A' : 'C';
    return '$orgPrefix${organizationId.padLeft(6, '0')}';
  }

  Future<void> _initializeMockData() async {
    if (_isInitialized) return;
    
    try {
      AppLogger.info('Initializing mock finance data');
      
      // Load mock data from JSON file
      final String jsonString = await rootBundle.loadString('financial_entries.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      
      _mockEntries = jsonData.map((entry) {
        final data = entry as Map<String, dynamic>;
        
        // Convert Firestore timestamp to DateTime
        final timestamp = data['date'] as Map<String, dynamic>;
        final date = DateTime.fromMillisecondsSinceEpoch(
          (timestamp['_seconds'] as int) * 1000,
        );
        
        final amount = (data['amount'] as num).toDouble();
        final isExpense = amount < 0;
        
        return FinanceEntry(
          id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          date: date,
          program: Program(
            id: data['programId'] as String,
            name: data['programName'] as String,
            category: 'unknown',
            isSystemDefault: false,
            financialType: isExpense ? FinancialType.expenseOnly : FinancialType.incomeOnly,
            isEnabled: true,
            isAssembly: false,
          ),
          amount: amount.abs(), // Store as positive, use isExpense flag
          paymentMethod: data['paymentMethod'] as String,
          checkNumber: null,
          description: data['description'] as String,
          isExpense: isExpense,
        );
      }).toList();
      
      _isInitialized = true;
      AppLogger.info('Mock finance data initialized with ${_mockEntries.length} entries');
    } catch (e, stackTrace) {
      AppLogger.error('Error initializing mock finance data', e, stackTrace);
      rethrow;
    }
  }

  Future<List<FinanceEntry>> getFinanceEntries(
    String organizationId,
    bool isAssembly,
  ) async {
    try {
      await _initializeMockData();
      
      final formattedOrgId = _getFormattedOrgId(organizationId, isAssembly);
      AppLogger.info('=== LOADING MOCK FINANCIAL ENTRIES ===');
      AppLogger.info('Organization: $formattedOrgId');
      AppLogger.info('Type: ${isAssembly ? 'Assembly' : 'Council'}');
      
      // Filter entries by current and previous year
      final currentYear = DateTime.now().year;
      final filteredEntries = _mockEntries.where((entry) {
        final entryYear = entry.date.year;
        return entryYear == currentYear || entryYear == currentYear - 1;
      }).toList();
      
      // Sort by date (newest first)
      filteredEntries.sort((a, b) => b.date.compareTo(a.date));
      
      // Log summary of entries
      final incomeEntries = filteredEntries.where((e) => !e.isExpense).toList();
      final expenseEntries = filteredEntries.where((e) => e.isExpense).toList();
      final totalIncome = incomeEntries.fold<double>(0, (sum, e) => sum + e.amount);
      final totalExpenses = expenseEntries.fold<double>(0, (sum, e) => sum + e.amount);
      
      AppLogger.info('=== MOCK FINANCIAL ENTRIES SUMMARY ===');
      AppLogger.info('Total entries: ${filteredEntries.length}');
      AppLogger.info('Income entries: ${incomeEntries.length} (Total: \$${totalIncome.toStringAsFixed(2)})');
      AppLogger.info('Expense entries: ${expenseEntries.length} (Total: \$${totalExpenses.toStringAsFixed(2)})');
      AppLogger.info('Net: \$${(totalIncome - totalExpenses).toStringAsFixed(2)}');
      AppLogger.info('=====================================');
      
      return filteredEntries;
    } catch (e, stackTrace) {
      AppLogger.error('Error getting mock finance entries', e);
      AppLogger.error('Stack trace:', stackTrace);
      rethrow;
    }
  }

  Future<void> addIncomeEntry({
    required String organizationId,
    required bool isAssembly,
    required DateTime date,
    required double amount,
    required String description,
    required PaymentMethod paymentMethod,
    required String programId,
    required String programName,
  }) async {
    try {
      await _initializeMockData();
      
      final user = _authService.currentUser;
      if (user == null) throw Exception('No authenticated user found');
      
      final entry = FinanceEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: date,
        program: Program(
          id: programId,
          name: programName,
          category: 'unknown',
          isSystemDefault: false,
          financialType: FinancialType.incomeOnly,
          isEnabled: true,
          isAssembly: isAssembly,
        ),
        amount: amount,
        paymentMethod: paymentMethod.name,
        checkNumber: null,
        description: description,
        isExpense: false,
      );
      
      _mockEntries.add(entry);
      AppLogger.info('Added mock income entry: \$${amount.toStringAsFixed(2)} for $programName');
    } catch (e) {
      AppLogger.error('Error adding mock income entry', e);
      rethrow;
    }
  }

  Future<void> addExpenseEntry({
    required String organizationId,
    required bool isAssembly,
    required DateTime date,
    required double amount,
    required String description,
    required PaymentMethod paymentMethod,
    required String programId,
    required String programName,
    String? checkNumber,
  }) async {
    try {
      await _initializeMockData();
      
      final user = _authService.currentUser;
      if (user == null) throw Exception('No authenticated user found');
      
      final entry = FinanceEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: date,
        program: Program(
          id: programId,
          name: programName,
          category: 'unknown',
          isSystemDefault: false,
          financialType: FinancialType.expenseOnly,
          isEnabled: true,
          isAssembly: isAssembly,
        ),
        amount: amount,
        paymentMethod: paymentMethod.name,
        checkNumber: checkNumber,
        description: description,
        isExpense: true,
      );
      
      _mockEntries.add(entry);
      AppLogger.info('Added mock expense entry: \$${amount.toStringAsFixed(2)} for $programName');
    } catch (e) {
      AppLogger.error('Error adding mock expense entry', e);
      rethrow;
    }
  }

  Future<void> updateFinanceEntry(FinanceEntry entry) async {
    try {
      await _initializeMockData();
      
      final index = _mockEntries.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        _mockEntries[index] = entry;
        AppLogger.info('Updated mock finance entry: ${entry.id}');
      } else {
        throw Exception('Entry not found: ${entry.id}');
      }
    } catch (e) {
      AppLogger.error('Error updating mock finance entry', e);
      rethrow;
    }
  }

  Future<void> deleteFinanceEntry(String entryId) async {
    try {
      await _initializeMockData();
      
      final index = _mockEntries.indexWhere((e) => e.id == entryId);
      if (index != -1) {
        final entry = _mockEntries.removeAt(index);
        AppLogger.info('Deleted mock finance entry: ${entry.id}');
      } else {
        throw Exception('Entry not found: $entryId');
      }
    } catch (e) {
      AppLogger.error('Error deleting mock finance entry', e);
      rethrow;
    }
  }

  // Method to clear mock data (useful for testing)
  void clearMockData() {
    _mockEntries.clear();
    _isInitialized = false;
    AppLogger.info('Mock finance data cleared');
  }

  // Method to add custom mock entries (useful for testing)
  void addMockEntry(FinanceEntry entry) {
    _mockEntries.add(entry);
    AppLogger.info('Added custom mock entry: ${entry.id}');
  }
} 