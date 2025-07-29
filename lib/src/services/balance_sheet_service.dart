import '../models/finance_entry.dart';
import '../models/program.dart';
import 'finance_service.dart';
import 'program_service.dart';
import '../utils/logger.dart';

class BalanceSheetData {
  final String year;
  final List<BalanceSheetRow> incomeRows;
  final List<BalanceSheetRow> expenseRows;
  final Map<int, double> monthlyIncomeTotals; // month -> total
  final Map<int, double> monthlyExpenseTotals; // month -> total
  final double yearlyIncomeTotal;
  final double yearlyExpenseTotal;
  final double yearlyNetTotal; // income - expenses

  BalanceSheetData({
    required this.year,
    required this.incomeRows,
    required this.expenseRows,
    required this.monthlyIncomeTotals,
    required this.monthlyExpenseTotals,
    required this.yearlyIncomeTotal,
    required this.yearlyExpenseTotal,
    required this.yearlyNetTotal,
  });
}

class BalanceSheetRow {
  final String programName;
  final String programId;
  final Map<int, double> monthlyAmounts; // month -> amount (0.00 if no data)
  final double yearlyTotal;

  BalanceSheetRow({
    required this.programName,
    required this.programId,
    required this.monthlyAmounts,
    required this.yearlyTotal,
  });
}

class BalanceSheetService {
  final FinanceService _financeService = FinanceService();
  final ProgramService _programService = ProgramService();

  Future<BalanceSheetData> getBalanceSheetData(
    String organizationId,
    String year,
  ) async {
    try {
      AppLogger.debug('Getting balance sheet data for organization: $organizationId, year: $year');

      // Get all finance entries for the year
      final entries = await _getFinanceEntriesForYear(organizationId, year);
      
      // Get all programs for the organization
      final programs = await _getAllPrograms(organizationId);
      
      // Aggregate the data
      return aggregateData(entries, programs, year);
    } catch (e, stackTrace) {
      AppLogger.error('Error getting balance sheet data', e);
      AppLogger.error('Stack trace:', stackTrace);
      rethrow;
    }
  }

  Future<List<Program>> _getAllPrograms(String organizationId) async {
    try {
      // Load system programs
      final programsData = await _programService.loadSystemPrograms();
      
      // Load program states
      await _programService.loadProgramStates(programsData, organizationId);
      
      // Get custom programs
      final customPrograms = await _programService.getCustomPrograms(organizationId);
      
      // Determine if this is assembly or council based on organization ID prefix
      final isAssembly = organizationId.startsWith('A');
      final systemPrograms = isAssembly ? programsData.assemblyPrograms : programsData.councilPrograms;
      
      // Combine system and custom programs
      final List<Program> allPrograms = [];
      
      // Add system programs
      for (var categoryPrograms in systemPrograms.values) {
        allPrograms.addAll(categoryPrograms);
      }
      
      // Add custom programs
      allPrograms.addAll(customPrograms);
      
      AppLogger.debug('Retrieved ${allPrograms.length} total programs for organization: $organizationId');
      return allPrograms;
    } catch (e, stackTrace) {
      AppLogger.error('Error getting all programs', e);
      AppLogger.error('Stack trace:', stackTrace);
      rethrow;
    }
  }

  Future<List<FinanceEntry>> _getFinanceEntriesForYear(
    String organizationId,
    String year,
  ) async {
    try {
      final yearInt = int.parse(year);
      final startOfYear = DateTime(yearInt, 1, 1);
      final endOfYear = DateTime(yearInt, 12, 31, 23, 59, 59);
      
      AppLogger.debug('Getting finance entries for year: $yearInt');
      
      // Get all entries for the organization
      final allEntries = await _financeService.getFinanceEntries(organizationId);
      
      // Filter by year
      final yearEntries = allEntries.where((entry) => 
        entry.date.isAfter(startOfYear.subtract(const Duration(days: 1))) &&
        entry.date.isBefore(endOfYear.add(const Duration(days: 1)))
      ).toList();
      
      AppLogger.debug('Found ${yearEntries.length} entries for year $yearInt');
      return yearEntries;
    } catch (e, stackTrace) {
      AppLogger.error('Error getting finance entries for year', e);
      AppLogger.error('Stack trace:', stackTrace);
      rethrow;
    }
  }

  BalanceSheetData aggregateData(
    List<FinanceEntry> entries,
    List<Program> programs,
    String year,
  ) {
    // Initialize monthly totals maps
    final Map<int, double> monthlyIncomeTotals = {};
    final Map<int, double> monthlyExpenseTotals = {};
    
    // Initialize all months with 0.00
    for (int month = 1; month <= 12; month++) {
      monthlyIncomeTotals[month] = 0.0;
      monthlyExpenseTotals[month] = 0.0;
    }

    // Group entries by program and type
    final Map<String, Map<int, double>> programIncome = {};
    final Map<String, Map<int, double>> programExpenses = {};
    
    // Initialize all programs with 0.00 for all months
    for (final program in programs) {
      if (program.isEnabled) {
        programIncome[program.id] = {};
        programExpenses[program.id] = {};
        for (int month = 1; month <= 12; month++) {
          programIncome[program.id]![month] = 0.0;
          programExpenses[program.id]![month] = 0.0;
        }
      }
    }

    // Process each entry
    for (final entry in entries) {
      final month = entry.date.month;
      final programId = entry.program.id;
      
      // Initialize program if not already done (for programs with financial activity but not in enabled list)
      if (!programIncome.containsKey(programId)) {
        programIncome[programId] = {};
        programExpenses[programId] = {};
        for (int m = 1; m <= 12; m++) {
          programIncome[programId]![m] = 0.0;
          programExpenses[programId]![m] = 0.0;
        }
      }

      if (entry.isExpense) {
        programExpenses[programId]![month] = (programExpenses[programId]![month] ?? 0.0) + entry.amount;
        monthlyExpenseTotals[month] = (monthlyExpenseTotals[month] ?? 0.0) + entry.amount;
      } else {
        programIncome[programId]![month] = (programIncome[programId]![month] ?? 0.0) + entry.amount;
        monthlyIncomeTotals[month] = (monthlyIncomeTotals[month] ?? 0.0) + entry.amount;
      }
    }

    // Create income rows
    final List<BalanceSheetRow> incomeRows = [];
    for (final entry in programIncome.entries) {
      final programId = entry.key;
      final monthlyAmounts = entry.value;
      
      // Find program name
      String programName = '';
      for (final program in programs) {
        if (program.id == programId) {
          programName = program.name;
          break;
        }
      }
      
      // If program not found in enabled list, use the name from the first entry
      if (programName.isEmpty) {
        for (final financeEntry in entries) {
          if (financeEntry.program.id == programId) {
            programName = financeEntry.program.name;
            break;
          }
        }
      }
      
      // Calculate yearly total
      final yearlyTotal = monthlyAmounts.values.fold(0.0, (sum, amount) => sum + amount);
      
      // Only add row if there's income activity
      if (yearlyTotal > 0) {
        incomeRows.add(BalanceSheetRow(
          programName: programName,
          programId: programId,
          monthlyAmounts: Map.from(monthlyAmounts),
          yearlyTotal: yearlyTotal,
        ));
      }
    }

    // Create expense rows
    final List<BalanceSheetRow> expenseRows = [];
    for (final entry in programExpenses.entries) {
      final programId = entry.key;
      final monthlyAmounts = entry.value;
      
      // Find program name
      String programName = '';
      for (final program in programs) {
        if (program.id == programId) {
          programName = program.name;
          break;
        }
      }
      
      // If program not found in enabled list, use the name from the first entry
      if (programName.isEmpty) {
        for (final financeEntry in entries) {
          if (financeEntry.program.id == programId) {
            programName = financeEntry.program.name;
            break;
          }
        }
      }
      
      // Calculate yearly total
      final yearlyTotal = monthlyAmounts.values.fold(0.0, (sum, amount) => sum + amount);
      
      // Only add row if there's expense activity
      if (yearlyTotal > 0) {
        expenseRows.add(BalanceSheetRow(
          programName: programName,
          programId: programId,
          monthlyAmounts: Map.from(monthlyAmounts),
          yearlyTotal: yearlyTotal,
        ));
      }
    }

    // Sort rows by program name
    incomeRows.sort((a, b) => a.programName.compareTo(b.programName));
    expenseRows.sort((a, b) => a.programName.compareTo(b.programName));

    // Calculate yearly totals
    final yearlyIncomeTotal = monthlyIncomeTotals.values.fold(0.0, (sum, amount) => sum + amount);
    final yearlyExpenseTotal = monthlyExpenseTotals.values.fold(0.0, (sum, amount) => sum + amount);
    final yearlyNetTotal = yearlyIncomeTotal - yearlyExpenseTotal;

    AppLogger.debug('Balance sheet data created: ${incomeRows.length} income rows, ${expenseRows.length} expense rows');

    return BalanceSheetData(
      year: year,
      incomeRows: incomeRows,
      expenseRows: expenseRows,
      monthlyIncomeTotals: monthlyIncomeTotals,
      monthlyExpenseTotals: monthlyExpenseTotals,
      yearlyIncomeTotal: yearlyIncomeTotal,
      yearlyExpenseTotal: yearlyExpenseTotal,
      yearlyNetTotal: yearlyNetTotal,
    );
  }
} 