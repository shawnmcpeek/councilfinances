import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import '../utils/logger.dart';
import '../services/user_service.dart';
import '../services/report_file_saver.dart' show saveOrShareFile;
import 'base_pdf_report_service.dart';

import 'audit_field_map.dart';

class SemiAnnualAuditService extends BasePdfReportService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();
  static const String _auditReportTemplate = 'audit2_1295_p.pdf';
  static const String _fillAuditReportUrl = 'https://fwcqtjsqetqavdhkahzy.supabase.co/functions/v1/fill-audit-report';

  @override
  String get templatePath => _auditReportTemplate;

  Future<void> generateAuditReport(String period, int year, [Map<String, String>? manualValues]) async {
    try {
      AppLogger.info('Generating semi-annual audit report for $period $year');

      // 1. Get report data with manual values
      final data = await _getAuditData(period, year, manualValues);
      AppLogger.debug('Got audit data: $data');

      // 3. Load PDF template
      final ByteData templateData = await rootBundle.load('assets/forms/audit2_1295_p.pdf');
      final Uint8List templateBytes = templateData.buffer.asUint8List();
      final String templateBase64 = base64Encode(templateBytes);

      // 4. Call Supabase Edge Function to fill the PDF
      final response = await http.post(
        Uri.parse(_fillAuditReportUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_supabase.auth.currentSession?.accessToken}',
        },
        body: json.encode({
          ...data,
          'period': period == 'June' ? 'January-June' : 'July-December',
          'year': year,
          'pdfTemplate': templateBase64,
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

  Future<Map<String, dynamic>> _getAuditData(String period, int year, [Map<String, String>? manualValues]) async {
    try {
      // Phase 1: Get Supabase data and calculate program totals
      final supabaseData = await getSupabaseData(period, year);
      
      // Phase 2: Add manual values with proper field mapping
      final Map<String, dynamic> data = Map<String, dynamic>.from(supabaseData);
      if (manualValues != null) {
        // Debug logging for manual values
        AppLogger.info('Manual values received: $manualValues');
        if (manualValues.containsKey('Text73')) {
          AppLogger.info('Text73 (Undeposited funds) value: ${manualValues['Text73']}');
        } else {
          AppLogger.info('Text73 (Undeposited funds) NOT found in manual values');
        }
        
        // Map PDF field names to expected field names for Supabase function
        final Map<String, String> mappedValues = {};
        for (final entry in manualValues.entries) {
          final pdfFieldName = entry.key;
          final value = entry.value;
          
          // Map PDF field names to expected field names
          switch (pdfFieldName) {
            case 'Text50':
              mappedValues['manual_income_1'] = value;
              break;
            case 'Text59':
              mappedValues['manual_income_2'] = value;
              break;
            case 'Text61':
              mappedValues['treasurer_cash_beginning'] = value;
              break;
            case 'Text62':
              mappedValues['treasurer_received_financial_secretary'] = value;
              break;
            case 'Text63':
              mappedValues['treasurer_transfers_from_savings'] = value;
              break;
            case 'Text64':
              mappedValues['treasurer_interest_earned'] = value;
              break;
            case 'Text66':
              mappedValues['treasurer_supreme_per_capita'] = value;
              break;
            case 'Text67':
              mappedValues['treasurer_state_per_capita'] = value;
              break;
            case 'Text68':
              mappedValues['treasurer_general_council_expenses'] = value;
              break;
            case 'Text69':
              mappedValues['treasurer_transfers_to_savings'] = value;
              break;
            case 'Text70':
              mappedValues['treasurer_miscellaneous'] = value;
              break;
            case 'Text73':
              mappedValues['net_council_verify'] = value;
              break;
            case 'Text74':
              mappedValues['manual_membership_1'] = value;
              break;
            case 'Text75':
              mappedValues['manual_membership_2'] = value;
              break;
            case 'Text76':
              mappedValues['manual_membership_3'] = value;
              break;
            case 'Text77':
              mappedValues['membership_count'] = value;
              break;
            case 'Text78':
              mappedValues['membership_dues_total'] = value;
              break;
            case 'Text84':
              mappedValues['manual_disbursement_1'] = value;
              break;
            case 'Text85':
              mappedValues['manual_disbursement_2'] = value;
              break;
            case 'Text86':
              mappedValues['manual_disbursement_3'] = value;
              break;
            case 'Text89':
              mappedValues['manual_field_1'] = value;
              break;
            case 'Text90':
              mappedValues['manual_field_2'] = value;
              break;
            case 'Text91':
              mappedValues['manual_field_3'] = value;
              break;
            case 'Text92':
              mappedValues['manual_field_4'] = value;
              break;
            case 'Text93':
              mappedValues['manual_field_5'] = value;
              break;
            case 'Text95':
              mappedValues['manual_field_6'] = value;
              break;
            case 'Text96':
              mappedValues['manual_field_7'] = value;
              break;
            case 'Text97':
              mappedValues['manual_field_8'] = value;
              break;
            case 'Text98':
              mappedValues['manual_field_9'] = value;
              break;
            case 'Text99':
              mappedValues['manual_field_10'] = value;
              break;
            case 'Text100':
              mappedValues['manual_field_11'] = value;
              break;
            case 'Text101':
              mappedValues['manual_field_12'] = value;
              break;
            case 'Text102':
              mappedValues['manual_field_13'] = value;
              break;
            case 'Text104':
              mappedValues['manual_field_14'] = value;
              break;
            case 'Text105':
              mappedValues['manual_field_15'] = value;
              break;
            case 'Text106':
              mappedValues['manual_field_16'] = value;
              break;
            case 'Text107':
              mappedValues['manual_field_17'] = value;
              break;
            case 'Text108':
              mappedValues['manual_field_18'] = value;
              break;
            case 'Text109':
              mappedValues['manual_field_19'] = value;
              break;
            case 'Text110':
              mappedValues['manual_field_20'] = value;
              break;
            default:
              // Keep original field name if no mapping found
              mappedValues[pdfFieldName] = value;
              break;
          }
        }
        data.addAll(mappedValues);
        
        // Debug logging for mapped values
        AppLogger.info('Mapped values: $mappedValues');
        if (mappedValues.containsKey('net_council_verify')) {
          AppLogger.info('net_council_verify mapped value: ${mappedValues['net_council_verify']}');
        } else {
          AppLogger.info('net_council_verify NOT found in mapped values');
        }
      }
      
      // Phase 3: Run final calculations using both datasets
      final finalData = await _runFinalCalculations(data);
      
      return finalData;
    } catch (e, stackTrace) {
      AppLogger.error('Error getting audit data', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSupabaseData(String period, int year) async {
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
        'council_city': userProfile.councilCity ?? '',
        'organization_name': 'Council ${userProfile.councilNumber}',
        'year': AuditFieldMap.getYearSuffix(year),
      };

      // Get transactions for the period
      AppLogger.info('Fetching transactions for period: $period, year: $year, dateRange: ${dateRange.start} to ${dateRange.end}');
      final transactions = await _getTransactionsForPeriod(
        organizationId,
        dateRange.start,
        dateRange.end,
      );
      AppLogger.info('Found ${transactions.length} transactions');
      if (transactions.isNotEmpty) {
        AppLogger.info('Sample transactions: ${transactions.take(3).map((t) => '${t['program']}: ${t['amount']}').join(', ')}');
      }

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

      return data;
    } catch (e, stackTrace) {
      AppLogger.error('Error getting Supabase data', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _runFinalCalculations(Map<String, dynamic> data) async {
    try {
      // Calculate totals using both Supabase and manual data
      data['total_income'] = _calculateTotalIncome(data);
      data['total_interest'] = _calculateTotalInterest(data);
      data['total_expenses'] = _calculateTotalExpenses(data);
      data['net_council'] = _calculateNetCouncil(data);
      // Only set net_council_verify to null if no manual value was provided
      if (!data.containsKey('net_council_verify')) {
        data['net_council_verify'] = null;
      }
      data['total_membership'] = _calculateTotalMembership(data);
      data['net_membership'] = _calculateNetMembership(data);
      data['total_disbursements_verify'] = _calculateTotalDisbursementsVerify(data);
      
             // Calculate PDF-specific fields
       data['cash_on_hand_end_period'] = _calculateCashOnHandEndPeriod(data);
       data['total_disbursements_sum'] = _calculateTotalDisbursementsSum(data);
       
       // Calculate Schedule B Treasurer fields
       data['treasurer_total_receipts'] = _calculateTreasurerTotalReceipts(data);
       data['treasurer_total_disbursements'] = _calculateTreasurerTotalDisbursements(data);
       data['treasurer_net_balance'] = _calculateTreasurerNetBalance(data);
       
       // Calculate asset totals
       data['total_assets'] = _calculateTotalAssets(data);
       data['total_assets_verify'] = _calculateTotalAssetsVerify(data);
       
       // Calculate liability totals
       data['total_liabilities'] = _calculateTotalLiabilities(data);
       
       // Add calculated values to data map for Supabase function
       data['Text65'] = data['treasurer_total_receipts']; // Total receipts
       data['Text71'] = data['treasurer_total_disbursements']; // Total disbursements  
       data['Text72'] = data['treasurer_net_balance']; // Net balance
       data['Text87'] = data['total_assets']; // Total assets (Text64 + Text65 + Text66)
       data['Text68'] = data['total_assets_verify']; // Total assets verify (Text83 + Text87)
       data['Text103'] = data['total_liabilities']; // Total liabilities (Text98 + Text100 + Text102)

       // Debug logging for Text60 calculation
       AppLogger.info('Text60 calculation debug:');
       AppLogger.info('  Text58 (total_income): ${data['total_income']}');
       AppLogger.info('  Text59 (manual_income_2): ${data['manual_income_2']}');
       AppLogger.info('  Text60 (calculated): ${data['cash_on_hand_end_period']}');

       return data;
    } catch (e, stackTrace) {
      AppLogger.error('Error running final calculations', e, stackTrace);
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
        AppLogger.info('Querying income for org: $organizationId, date range: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');
        final incomeResponse = await _supabase
            .from('finance_entries')
            .select()
            .eq('organization_id', organizationId)
            .eq('is_expense', false)
            .gte('date', startDate.toIso8601String())
            .lte('date', endDate.toIso8601String());
        AppLogger.info('Income response: ${incomeResponse.length} records');
            
        for (final data in incomeResponse) {
          final program = data['program_name'] ?? data['programName'] ?? data['program']?['name'] ?? 'Unknown';
          final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
          final date = _parseDate(data['date']);
          
          AppLogger.info('Processing income record: program=$program, amount=$amount, date=$date');
          
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
        AppLogger.info('Querying expenses for org: $organizationId, date range: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');
        final expenseResponse = await _supabase
            .from('finance_entries')
            .select()
            .eq('organization_id', organizationId)
            .eq('is_expense', true)
            .gte('date', startDate.toIso8601String())
            .lte('date', endDate.toIso8601String());
        AppLogger.info('Expense response: ${expenseResponse.length} records');
            
        for (final data in expenseResponse) {
          final program = data['program_name'] ?? data['programName'] ?? data['program']?['name'] ?? 'Unknown';
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
        .where((t) => t['program'] == 'Interest')
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
    // Text58 should be: Cash on hand beginning + Cash received (dues + other sources)
    final cashOnHandBeginning = _parseCurrency(data['manual_income_1']); // Text50
    final membershipDues = _parseCurrency(data['membership_dues']); // Text51
    final topProgram1Amount = _parseCurrency(data['top_program_1_amount']); // Text53
    final topProgram2Amount = _parseCurrency(data['top_program_2_amount']); // Text55
    final otherProgramsAmount = _parseCurrency(data['other_programs_amount']); // Text57

    final total = cashOnHandBeginning + membershipDues + topProgram1Amount + topProgram2Amount + otherProgramsAmount;
    
    AppLogger.info('Text58 (Total Cash Received) calculation:');
    AppLogger.info('  cashOnHandBeginning (Text50): $cashOnHandBeginning');
    AppLogger.info('  membershipDues (Text51): $membershipDues');
    AppLogger.info('  topProgram1Amount (Text53): $topProgram1Amount');
    AppLogger.info('  topProgram2Amount (Text55): $topProgram2Amount');
    AppLogger.info('  otherProgramsAmount (Text57): $otherProgramsAmount');
    AppLogger.info('  Text58 total: $total');
    
    return AuditFieldMap.formatCurrency(total);
  }

  String _calculateCashOnHandEndPeriod(Map<String, dynamic> data) {
    // Text60 = Text58 (Total Cash Received) - Text59 (Transferred to Treasurer)
    final totalCashReceived = _parseCurrency(data['total_income']); // Text58
    final transferredToTreasurer = _parseCurrency(data['manual_income_2']); // Text59

    AppLogger.info('Text60 calculation breakdown:');
    AppLogger.info('  totalCashReceived (Text58): $totalCashReceived');
    AppLogger.info('  transferredToTreasurer (Text59): $transferredToTreasurer');
    AppLogger.info('  Text60 result: ${totalCashReceived - transferredToTreasurer}');

    return AuditFieldMap.formatCurrency(totalCashReceived - transferredToTreasurer);
  }

  String _calculateTotalDisbursementsSum(Map<String, dynamic> data) {
    final manualField1 = _parseCurrency(data['manual_field_1']);
    final manualField2 = _parseCurrency(data['manual_field_2']);
    final manualField3 = _parseCurrency(data['manual_field_3']);
    final manualField4 = _parseCurrency(data['manual_field_4']);
    final manualField5 = _parseCurrency(data['manual_field_5']);
    final manualField6 = _parseCurrency(data['manual_field_6']);
    final manualField7 = _parseCurrency(data['manual_field_7']);
    final manualField8 = _parseCurrency(data['manual_field_8']);
    final manualField9 = _parseCurrency(data['manual_field_9']);
    final manualField10 = _parseCurrency(data['manual_field_10']);
    final manualField11 = _parseCurrency(data['manual_field_11']);
    final manualField12 = _parseCurrency(data['manual_field_12']);
    final manualField13 = _parseCurrency(data['manual_field_13']);

    final total = manualField1 + manualField2 + manualField3 + manualField4 + manualField5 +
                  manualField6 + manualField7 + manualField8 + manualField9 + manualField10 +
                  manualField11 + manualField12 + manualField13;

    return AuditFieldMap.formatCurrency(total);
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
    final membershipCount = _parseCurrency(data['membership_count']);
    final membershipDuesTotal = _parseCurrency(data['membership_dues_total']);

    final total = netCouncil + manualMembership1 + manualMembership2 + manualMembership3 + membershipCount + membershipDuesTotal;
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

       // Schedule B Treasurer calculations
    String _calculateTreasurerTotalReceipts(Map<String, dynamic> data) {
      final receivedFromFinancialSecretary = _parseCurrency(data['treasurer_received_financial_secretary']);
      final transfersFromSavings = _parseCurrency(data['treasurer_transfers_from_savings']);
      final interestEarned = _parseCurrency(data['treasurer_interest_earned']);

      final total = receivedFromFinancialSecretary + transfersFromSavings + interestEarned;
      return AuditFieldMap.formatCurrency(total);
    }

    String _calculateTreasurerTotalDisbursements(Map<String, dynamic> data) {
      final supremePerCapita = _parseCurrency(data['treasurer_supreme_per_capita']);
      final statePerCapita = _parseCurrency(data['treasurer_state_per_capita']);
      final generalCouncilExpenses = _parseCurrency(data['treasurer_general_council_expenses']);
      final transfersToSavings = _parseCurrency(data['treasurer_transfers_to_savings']);
      final miscellaneous = _parseCurrency(data['treasurer_miscellaneous']);

      final total = supremePerCapita + statePerCapita + generalCouncilExpenses + transfersToSavings + miscellaneous;
      return AuditFieldMap.formatCurrency(total);
    }

        String _calculateTreasurerNetBalance(Map<String, dynamic> data) {
       final cashBeginning = _parseCurrency(data['treasurer_cash_beginning']);
       final totalReceipts = _parseCurrency(data['treasurer_total_receipts']);
       final totalDisbursements = _parseCurrency(data['treasurer_total_disbursements']);

       final netBalance = cashBeginning + totalReceipts - totalDisbursements;
       return AuditFieldMap.formatCurrency(netBalance);
     }

  String _calculateTotalAssets(Map<String, dynamic> data) {
    final interestEarned = _parseCurrency(data['treasurer_interest_earned']);
    final totalReceipts = _parseCurrency(data['treasurer_total_receipts']);
    final netBalance = _parseCurrency(data['treasurer_net_balance']);

    final total = interestEarned + totalReceipts + netBalance;
    return AuditFieldMap.formatCurrency(total);
  }

  String _calculateTotalAssetsVerify(Map<String, dynamic> data) {
    final netMembership = _parseCurrency(data['net_membership']);
    final totalAssets = _parseCurrency(data['total_assets']);

    final total = netMembership + totalAssets;
    return AuditFieldMap.formatCurrency(total);
  }

  String _calculateTotalLiabilities(Map<String, dynamic> data) {
    final liability1Amount = _parseCurrency(data['liability_1_amount']);
    final liability2Amount = _parseCurrency(data['liability_2_amount']);
    final liability3Amount = _parseCurrency(data['liability_3_amount']);

    final total = liability1Amount + liability2Amount + liability3Amount;
    return AuditFieldMap.formatCurrency(total);
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