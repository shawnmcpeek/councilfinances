import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/logger.dart';
import '../services/user_service.dart';
import '../services/report_file_saver.dart' show saveOrShareFile;
import 'base_pdf_report_service.dart';

import 'audit_field_map.dart';

class SemiAnnualAuditService extends BasePdfReportService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();
  static const String _auditReportTemplate = 'audit2_1295_p.pdf';
  static const String _fillAuditReportUrl = 'https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/fillAuditReport';

  @override
  String get templatePath => _auditReportTemplate;

  Future<void> generateAuditReport(String period, int year, [Map<String, String>? manualValues]) async {
    try {
      AppLogger.info('Generating semi-annual audit report for $period $year');

      // 1. Get report data
      final data = await _getAuditData(period, year);
      AppLogger.debug('Got audit data: $data');

      // 2. Add manual values to data
      if (manualValues != null) {
        data.addAll(manualValues);
      }

      // 3. Call Firebase Function to fill the PDF
      final response = await http.post(
        Uri.parse(_fillAuditReportUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          ...data,
          'period': period,
          'year': year,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to generate PDF: ${response.body}');
      }

      // 4. Save or share the PDF
      final fileName = 'semi_annual_audit_${period.toLowerCase()}_$year.pdf';
      await saveOrShareFile(
        response.bodyBytes,
        fileName,
        'Semi-Annual Audit Report for $period $year'
      );

      AppLogger.info('Semi-annual audit report saved/shared successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error generating semi-annual audit report', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _getAuditData(String period, int year) async {
    try {
      // Get user profile for organization info
      final userProfile = await _userService.getUserProfile();
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      // Get date range for the period
      final dateRange = AuditFieldMap.getDateRangeForPeriod(period, year);

      // Get organization ID (council only for now)
      final organizationId = userProfile.getOrganizationId(false);

      // Initialize data map with basic info
      final Map<String, dynamic> data = {
        'council_number': userProfile.councilNumber.toString().padLeft(6, '0'),
        'organization_name': 'Council ${userProfile.councilNumber}',
        'year': AuditFieldMap.getYearSuffix(year),
        // Manual entry fields will be handled by the UI
      };

      // Get transactions for the period
      final transactions = await _getTransactionsForPeriod(
        organizationId,
        dateRange.start,
        dateRange.end,
      );

      // Calculate program totals
      final programTotals = _calculateProgramTotals(transactions);
      
      // Calculate membership dues
      final membershipDues = _calculateMembershipDues(transactions);
      data['membership_dues'] = AuditFieldMap.formatCurrency(membershipDues);

      // Get top programs
      final topPrograms = _getTopPrograms(programTotals);
      if (topPrograms.isNotEmpty) {
        data['top_program_1_name'] = topPrograms[0].name;
        data['top_program_1_amount'] = AuditFieldMap.formatCurrency(topPrograms[0].amount);
        if (topPrograms.length > 1) {
          data['top_program_2_name'] = topPrograms[1].name;
          data['top_program_2_amount'] = AuditFieldMap.formatCurrency(topPrograms[1].amount);
        }
      }

      // Calculate other programs total
      final otherProgramsTotal = _calculateOtherProgramsTotal(programTotals, topPrograms);
      data['other_programs_name'] = 'Other';
      data['other_programs_amount'] = AuditFieldMap.formatCurrency(otherProgramsTotal);

      // Calculate interest earned
      final interestEarned = _calculateInterestEarned(transactions);
      data['interest_earned'] = AuditFieldMap.formatCurrency(interestEarned);

      // Calculate per capita amounts
      final perCapita = _calculatePerCapitaAmounts(transactions);
      data['supreme_per_capita'] = AuditFieldMap.formatCurrency(perCapita.supreme);
      data['state_per_capita'] = AuditFieldMap.formatCurrency(perCapita.state);

      // Calculate other council programs
      final otherCouncilPrograms = _calculateOtherCouncilPrograms(transactions);
      data['other_council_programs'] = AuditFieldMap.formatCurrency(otherCouncilPrograms);

      // Calculate totals
      data['total_income'] = _calculateTotalIncome(data);
      data['net_income'] = _calculateNetIncome(data);
      data['total_interest'] = _calculateTotalInterest(data);
      data['total_expenses'] = _calculateTotalExpenses(data);
      data['net_council'] = _calculateNetCouncil(data);
      data['net_council_verify'] = data['net_council'];
      data['total_membership'] = _calculateTotalMembership(data);
      data['net_membership'] = _calculateNetMembership(data);
      data['total_disbursements_verify'] = _calculateTotalDisbursementsVerify(data);

      return data;
    } catch (e, stackTrace) {
      AppLogger.error('Error getting audit data', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _getTransactionsForPeriod(
    String organizationId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final List<Map<String, dynamic>> allTransactions = [];
    final years = <int>{startDate.year, endDate.year};
    
    for (final year in years) {
      try {
        // Fetch income
        final incomeResponse = await _supabase
            .from('finance_entries')
            .select()
            .eq('organizationId', organizationId)
            .eq('year', year.toString())
            .eq('type', 'income')
            .gte('date', startDate.toIso8601String())
            .lte('date', endDate.toIso8601String());
            
        for (final data in incomeResponse) {
          final program = data['programName'] ?? data['program']?['name'] ?? 'Unknown';
          final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
          final date = _parseDate(data['date']);
          
          if (date != null) {
            allTransactions.add({
              'program': program,
              'amount': amount,
              'date': date,
              'type': 'income',
            });
          }
        }

        // Fetch expenses
        final expenseResponse = await _supabase
            .from('finance_entries')
            .select()
            .eq('organizationId', organizationId)
            .eq('year', year.toString())
            .eq('type', 'expense')
            .gte('date', startDate.toIso8601String())
            .lte('date', endDate.toIso8601String());
            
        for (final data in expenseResponse) {
          final program = data['programName'] ?? data['program']?['name'] ?? 'Unknown';
          final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
          final date = _parseDate(data['date']);
          
          if (date != null) {
            allTransactions.add({
              'program': program,
              'amount': amount,
              'date': date,
              'type': 'expense',
            });
          }
        }
      } catch (e, stackTrace) {
        AppLogger.error('Error fetching transactions for year $year', e, stackTrace);
        // Continue with other years even if one fails
        continue;
      }
    }
    return allTransactions;
  }

  DateTime? _parseDate(dynamic dateValue) {
    if (dateValue is String) {
      return DateTime.tryParse(dateValue);
    } else if (dateValue is DateTime) {
      return dateValue;
    }
    return null;
  }

  Map<String, double> _calculateProgramTotals(List<Map<String, dynamic>> transactions) {
    final Map<String, double> totals = {};
    
    for (final transaction in transactions) {
      final program = transaction['program'] as String;
      final amount = (transaction['amount'] as num).toDouble();
      
      totals[program] = (totals[program] ?? 0) + amount;
    }
    
    return totals;
  }

  double _calculateMembershipDues(List<Map<String, dynamic>> transactions) {
    return transactions
        .where((t) => t['program'] == 'Membership Dues')
        .fold(0.0, (acc, t) => acc + (t['amount'] as num).toDouble());
  }

  List<ProgramTotal> _getTopPrograms(Map<String, double> programTotals) {
    final programs = programTotals.entries
        .where((e) => e.key != 'Membership Dues')
        .map((e) => ProgramTotal(e.key, e.value))
        .toList();
    
    programs.sort((a, b) => b.amount.compareTo(a.amount));
    return programs.take(2).toList();
  }

  double _calculateOtherProgramsTotal(
    Map<String, double> programTotals,
    List<ProgramTotal> topPrograms,
  ) {
    final topProgramNames = topPrograms.map((p) => p.name).toSet();
    return programTotals.entries
        .where((e) => e.key != 'Membership Dues' && !topProgramNames.contains(e.key))
        .fold(0.0, (acc, e) => acc + e.value);
  }

  double _calculateInterestEarned(List<Map<String, dynamic>> transactions) {
    return transactions
        .where((t) => t['program'] == 'Interest Earned')
        .fold(0.0, (acc, t) => acc + (t['amount'] as num).toDouble());
  }

  PerCapitaAmounts _calculatePerCapitaAmounts(List<Map<String, dynamic>> transactions) {
    double supreme = 0.0;
    double state = 0.0;

    for (final transaction in transactions) {
      final program = transaction['program'] as String;
      final amount = (transaction['amount'] as num).toDouble();

      if (program == 'Supreme Per Capita') {
        supreme += amount;
      } else if (program == 'State Per Capita') {
        state += amount;
      }
    }

    return PerCapitaAmounts(supreme, state);
  }

  double _calculateOtherCouncilPrograms(List<Map<String, dynamic>> transactions) {
    final councilPrograms = AuditFieldMap.defaultCouncilPrograms.toSet();
    return transactions
        .where((t) => councilPrograms.contains(t['program']))
        .fold(0.0, (acc, t) => acc + (t['amount'] as num).toDouble());
  }

  String _calculateTotalIncome(Map<String, dynamic> data) {
    final manualIncome1 = _parseCurrency(data['manual_income_1']);
    final membershipDues = _parseCurrency(data['membership_dues']);
    final topProgram1Amount = _parseCurrency(data['top_program_1_amount']);
    final topProgram2Amount = _parseCurrency(data['top_program_2_amount']);
    final otherProgramsAmount = _parseCurrency(data['other_programs_amount']);

    final total = manualIncome1 + membershipDues + topProgram1Amount + topProgram2Amount + otherProgramsAmount;
    return AuditFieldMap.formatCurrency(total);
  }

  String _calculateNetIncome(Map<String, dynamic> data) {
    final totalIncome = _parseCurrency(data['total_income']);
    final manualIncome2 = _parseCurrency(data['manual_income_2']);

    return AuditFieldMap.formatCurrency(totalIncome - manualIncome2);
  }

  String _calculateTotalInterest(Map<String, dynamic> data) {
    final interestEarned = _parseCurrency(data['interest_earned']);
    return AuditFieldMap.formatCurrency(interestEarned);
  }

  String _calculateTotalExpenses(Map<String, dynamic> data) {
    final otherCouncilPrograms = _parseCurrency(data['other_council_programs']);
    final manualExpense1 = _parseCurrency(data['manual_expense_1']);
    final manualExpense2 = _parseCurrency(data['manual_expense_2']);

    return AuditFieldMap.formatCurrency(otherCouncilPrograms + manualExpense1 + manualExpense2);
  }

  String _calculateNetCouncil(Map<String, dynamic> data) {
    final totalInterest = _parseCurrency(data['total_interest']);
    final totalExpenses = _parseCurrency(data['total_expenses']);

    return AuditFieldMap.formatCurrency(totalInterest - totalExpenses);
  }

  String _calculateTotalMembership(Map<String, dynamic> data) {
    final netCouncil = _parseCurrency(data['net_council']);
    final manualMembership1 = _parseCurrency(data['manual_membership_1']);
    final manualMembership2 = _parseCurrency(data['manual_membership_2']);
    final manualMembership3 = _parseCurrency(data['manual_membership_3']);
    final membershipDuesTotal = _parseCurrency(data['membership_dues_total']);

    final total = netCouncil + manualMembership1 + manualMembership2 + manualMembership3 + membershipDuesTotal;
    return AuditFieldMap.formatCurrency(total);
  }

  String _calculateNetMembership(Map<String, dynamic> data) {
    final totalMembership = _parseCurrency(data['total_membership']);
    final totalDisbursements = _parseCurrency(data['total_disbursements']);

    return AuditFieldMap.formatCurrency(totalMembership - totalDisbursements);
  }

  String _calculateTotalDisbursementsVerify(Map<String, dynamic> data) {
    final manualDisbursement1 = _parseCurrency(data['manual_disbursement_1']);
    final manualDisbursement2 = _parseCurrency(data['manual_disbursement_2']);
    final manualDisbursement3 = _parseCurrency(data['manual_disbursement_3']);
    final manualDisbursement4 = _parseCurrency(data['manual_disbursement_4']);

    // Verify that total disbursements match the sum of individual disbursements
    final calculatedTotal = manualDisbursement1 + manualDisbursement2 + manualDisbursement3 + manualDisbursement4;
    final reportedTotal = _parseCurrency(data['total_disbursements']);
    
    if ((calculatedTotal - reportedTotal).abs() > 0.01) {
      AppLogger.warning('Disbursement verification failed: calculated $calculatedTotal vs reported $reportedTotal');
    }
    
    return AuditFieldMap.formatCurrency(calculatedTotal);
  }

  double _parseCurrency(String? value) {
    if (value == null) return 0.0;
    // Remove currency symbols and commas
    final cleanValue = value.replaceAll(RegExp(r'[^\d.-]'), '');
    return double.tryParse(cleanValue) ?? 0.0;
  }
}

class ProgramTotal {
  final String name;
  final double amount;

  ProgramTotal(this.name, this.amount);
}

class PerCapitaAmounts {
  final double supreme;
  final double state;

  PerCapitaAmounts(this.supreme, this.state);
} 