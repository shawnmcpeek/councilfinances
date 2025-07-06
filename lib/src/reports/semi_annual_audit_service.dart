import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/logger.dart';
import '../services/report_file_saver.dart' show saveOrShareFile;
import 'base_pdf_report_service.dart';
import 'audit_field_map.dart';
import '../services/audit_firestore_data_service.dart';

class SemiAnnualAuditService extends BasePdfReportService {
  final AuditFirestoreDataService _firestoreService = AuditFirestoreDataService();
  static const String _auditReportTemplate = 'audit2_1295_p.pdf';
  static const String _fillAuditReportUrl = 'https://us-central1-council-finance.cloudfunctions.net/fillAuditReport';

  @override
  String get templatePath => _auditReportTemplate;

  Future<void> generateAuditReport(String period, int year, [Map<String, String>? manualValues]) async {
    try {
      AppLogger.info('Generating semi-annual audit report for $period $year');

      // 1. Get report data (Firestore + manual + calculations)
      final data = await _getAuditData(period, year, manualValues);
      AppLogger.debug('Got audit data: $data');

      // List of fields that should never be auto-filled (hand entry only)
      const handEntryOnlyFields = [
        'Text95','Text97','Text99','Text101','Text104','Text105','Text106','Text107','Text108','Text109','Text110'
      ];
      for (final key in handEntryOnlyFields) {
        data.remove(key);
      }

      // Print all calculated fields for debug
      for (final key in AuditFieldMap.autoCalculatedFields) {
        print('DEBUG: $key = ${data[key]}');
      }

      // Add debug output for all key calculated fields before sending to backend
      final debugFields = [
        'Text73','Text74','Text75','Text76','Text77','Text78','Text79','Text80','Text83','Text88',
        'Text69','Text70','manual_expense_1','manual_expense_2','total_disbursements_sum',
        'total_current_liabilities','net_current_assets','total_assets'
      ];
      for (final key in debugFields) {
        print('DEBUG FIELD $key: \'${data[key]}\'');
      }

      // DEBUG: Print the data being sent to the backend
      print('AUDIT PDF DATA SENT TO BACKEND:');
      print(json.encode({
        ...data,
        'period': period,
        'year': year,
      }));

      // === EXPLICITLY ASSIGN AND DEBUG ALL FIELDS ===
      // Manual fields (ensure correct mapping)
      data['Text50'] = data['Text50'] ?? data['manual_income_1'] ?? '0.00';
      data['Text59'] = data['Text59'] ?? '0.00';
      data['Text68'] = data['Text68'] ?? data['manual_expense_1'] ?? '0.00'; // General council expenses
      data['Text70'] = data['Text70'] ?? data['manual_expense_2'] ?? '0.00'; // Transfers to sav./other accts.
      data['Text74'] = data['Text74'] ?? data['manual_membership_1'] ?? '0.00';
      data['Text75'] = data['Text75'] ?? data['manual_membership_2'] ?? '0.00';
      data['Text76'] = data['Text76'] ?? data['manual_membership_3'] ?? '0.00';
      data['Text77'] = data['Text77'] ?? data['membership_count'] ?? '0.00';
      data['Text78'] = data['Text78'] ?? data['membership_dues_total'] ?? '0.00';
      data['Text84'] = data['Text84'] ?? data['manual_disbursement_1'] ?? '0.00';
      data['Text85'] = data['Text85'] ?? data['manual_disbursement_2'] ?? '0.00';
      data['Text86'] = data['Text86'] ?? data['manual_disbursement_3'] ?? '0.00';
      data['Text87'] = data['Text87'] ?? data['manual_disbursement_4'] ?? '0.00';
      data['Text89'] = data['Text89'] ?? data['manual_field_1'] ?? '0.00';
      data['Text90'] = data['Text90'] ?? data['manual_field_2'] ?? '0.00';
      data['Text91'] = data['Text91'] ?? data['manual_field_3'] ?? '0.00';
      data['Text92'] = data['Text92'] ?? data['manual_field_4'] ?? '0.00';
      data['Text93'] = data['Text93'] ?? data['manual_field_5'] ?? '0.00';
      data['Text95'] = data['Text95'] ?? data['manual_field_6'] ?? '0.00';
      data['Text96'] = data['Text96'] ?? data['manual_field_7'] ?? '0.00';
      data['Text97'] = data['Text97'] ?? data['manual_field_8'] ?? '0.00';
      data['Text98'] = data['Text98'] ?? data['manual_field_9'] ?? '0.00';
      data['Text99'] = data['Text99'] ?? data['manual_field_10'] ?? '0.00';
      data['Text100'] = data['Text100'] ?? data['manual_field_11'] ?? '0.00';
      data['Text101'] = data['Text101'] ?? data['manual_field_12'] ?? '0.00';
      data['Text102'] = data['Text102'] ?? data['manual_field_13'] ?? '0.00';
      // Calculated fields (ensure all are set)
      data['Text51'] = data['Text51'] ?? data['membership_dues'] ?? '0.00';
      data['Text58'] = data['Text58'] ?? '0.00';
      data['Text60'] = data['Text60'] ?? '0.00';
      data['Text64'] = data['Text64'] ?? data['interest_earned'] ?? '0.00';
      data['Text65'] = data['Text65'] ?? '0.00';
      data['Text66'] = data['Text66'] ?? data['supreme_per_capita'] ?? '0.00';
      data['Text67'] = data['Text67'] ?? data['state_per_capita'] ?? '0.00';
      data['Text69'] = data['Text69'] ?? '0.00'; // Not for council expenses
      data['Text71'] = data['Text71'] ?? '0.00';
      data['Text72'] = data['Text72'] ?? '0.00';
      data['Text73'] = data['Text73'] ?? '0.00';
      data['Text79'] = data['Text79'] ?? '0.00';
      data['Text80'] = data['Text80'] ?? '0.00';
      data['Text83'] = data['Text83'] ?? '0.00';
      data['Text88'] = data['Text88'] ?? '0.00';
      data['Text103'] = data['Text103'] ?? data['total_disbursements_sum'] ?? '0.00';
      // Debug print every field
      for (final key in data.keys) {
        print('DEBUG FINAL FIELD $key: ${data[key]}');
      }

      // === CALCULATE AND ASSIGN ALL FIELDS ===
      // Text73: Net council verify (should equal Text72)
      data['Text73'] = data['Text72'] ?? '0.00';
      print('DEBUG CALC Text73: ${data['Text73']}');

      // Text79: Total current assets = Text73 + Text74 + Text75 + Text76 + Text77 + Text78
      final text73 = _parseCurrency(data['Text73']);
      final text74 = _parseCurrency(data['Text74']);
      final text75 = _parseCurrency(data['Text75']);
      final text76 = _parseCurrency(data['Text76']);
      final text77 = _parseCurrency(data['Text77']);
      final text78 = _parseCurrency(data['Text78']);
      data['Text79'] = AuditFieldMap.formatCurrency(text73 + text74 + text75 + text76 + text77 + text78);
      print('DEBUG CALC Text79: ${data['Text79']}');

      // Text80: Total current liabilities = sum of Text89, Text90, Text91, Text92, Text93, Text96, Text98, Text100, Text102
      final text89 = _parseCurrency(data['Text89']);
      final text90 = _parseCurrency(data['Text90']);
      final text91 = _parseCurrency(data['Text91']);
      final text92 = _parseCurrency(data['Text92']);
      final text93 = _parseCurrency(data['Text93']);
      final text96 = _parseCurrency(data['Text96']);
      final text98 = _parseCurrency(data['Text98']);
      final text100 = _parseCurrency(data['Text100']);
      final text102 = _parseCurrency(data['Text102']);
      final totalCurrentLiabilities = text89 + text90 + text91 + text92 + text93 + text96 + text98 + text100 + text102;
      data['Text80'] = AuditFieldMap.formatCurrency(totalCurrentLiabilities);
      data['total_current_liabilities'] = data['Text80'];
      print('DEBUG CALC Text80: ${data['Text80']}');

      // Text83: Net current assets = Text79 - Text80
      final text79 = _parseCurrency(data['Text79']);
      final text80 = _parseCurrency(data['Text80']);
      data['Text83'] = AuditFieldMap.formatCurrency(text79 - text80);
      data['net_current_assets'] = data['Text83'];
      print('DEBUG CALC Text83: ${data['Text83']}');

      // Text88: Total assets = Text83 (if no other assets)
      data['Text88'] = data['Text83'];
      data['total_assets'] = data['Text88'];
      print('DEBUG CALC Text88: ${data['Text88']}');

      // total_disbursements_sum (Text103): sum of Text89, Text90, Text91, Text92, Text93, Text96, Text98, Text100, Text102
      data['total_disbursements_sum'] = AuditFieldMap.formatCurrency(totalCurrentLiabilities);
      data['Text103'] = data['total_disbursements_sum'];
      print('DEBUG CALC total_disbursements_sum/Text103: ${data['Text103']}');

      // 2. Call Firebase Function to fill the PDF
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

      // 3. Save or share the PDF
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
      AppLogger.info('=== STARTING AUDIT DATA GENERATION ===');
      AppLogger.info('Period: $period, Year: $year');

      // STEP 1: Get all Firestore data and calculations (Field B)
      AppLogger.info('Step 1: Fetching Firestore data...');
      final firestoreData = await _firestoreService.getAuditFirestoreData(period, year);
      AppLogger.info('Step 1 COMPLETE: Firestore data fetched and calculated');

      // STEP 2: Merge manual user data (Field A)
      AppLogger.info('Step 2: Merging manual user data...');
      final Map<String, dynamic> data = Map.from(firestoreData);
      
      if (manualValues != null) {
        for (final entry in manualValues.entries) {
          data[entry.key] = entry.value;
          AppLogger.info('Manual data added: ${entry.key} = ${entry.value}');
        }
      }
      AppLogger.info('Step 2 COMPLETE: Manual data merged');

      // STEP 3: Calculate all totals and dependent fields (Field C)
      AppLogger.info('Step 3: Calculating totals and dependent fields...');
      _calculateAllTotals(data);
      AppLogger.info('Step 3 COMPLETE: All calculations finished');

      AppLogger.info('=== AUDIT DATA GENERATION COMPLETE ===');
      return data;
    } catch (e, stackTrace) {
      AppLogger.error('Error getting audit data', e, stackTrace);
      rethrow;
    }
  }

  void _calculateAllTotals(Map<String, dynamic> data) {
    // Calculate all totals using complete data (manual + firestore)
    
    // Text51: Membership dues (from Firestore)
    data['Text51'] = data['membership_dues'] ?? '0.00';
    
    // Text64: Interest earned (from Firestore)
    data['Text64'] = data['interest_earned'] ?? '0.00';
    
    // Text66: Supreme per capita (from Firestore)
    data['Text66'] = data['supreme_per_capita'] ?? '0.00';
    
    // Text67: State per capita (from Firestore)
    data['Text67'] = data['state_per_capita'] ?? '0.00';
    
    // Text72: Net council verify (calculated)
    final text64 = _parseCurrency(data['Text64']);
    final text65 = _parseCurrency(data['Text65'] ?? '0.00');
    final text66 = _parseCurrency(data['Text66']);
    final text67 = _parseCurrency(data['Text67']);
    final text68 = _parseCurrency(data['Text68'] ?? '0.00');
    final text69 = _parseCurrency(data['Text69'] ?? '0.00');
    final text70 = _parseCurrency(data['Text70'] ?? '0.00');
    final text71 = _parseCurrency(data['Text71'] ?? '0.00');
    
    final netCouncil = text64 + text65 + text66 + text67 - text68 - text69 - text70 - text71;
    data['Text72'] = AuditFieldMap.formatCurrency(netCouncil);
    
    // Text73: Net council verify (should equal Text72)
    data['Text73'] = data['Text72'];
    
    // Text79: Total current assets
    final text73 = _parseCurrency(data['Text73']);
    final text74 = _parseCurrency(data['Text74'] ?? '0.00');
    final text75 = _parseCurrency(data['Text75'] ?? '0.00');
    final text76 = _parseCurrency(data['Text76'] ?? '0.00');
    final text77 = _parseCurrency(data['Text77'] ?? '0.00');
    final text78 = _parseCurrency(data['Text78'] ?? '0.00');
    data['Text79'] = AuditFieldMap.formatCurrency(text73 + text74 + text75 + text76 + text77 + text78);
    
    // Text80: Total current liabilities
    final text89 = _parseCurrency(data['Text89'] ?? '0.00');
    final text90 = _parseCurrency(data['Text90'] ?? '0.00');
    final text91 = _parseCurrency(data['Text91'] ?? '0.00');
    final text92 = _parseCurrency(data['Text92'] ?? '0.00');
    final text93 = _parseCurrency(data['Text93'] ?? '0.00');
    final text96 = _parseCurrency(data['Text96'] ?? '0.00');
    final text98 = _parseCurrency(data['Text98'] ?? '0.00');
    final text100 = _parseCurrency(data['Text100'] ?? '0.00');
    final text102 = _parseCurrency(data['Text102'] ?? '0.00');
    final totalCurrentLiabilities = text89 + text90 + text91 + text92 + text93 + text96 + text98 + text100 + text102;
    data['Text80'] = AuditFieldMap.formatCurrency(totalCurrentLiabilities);
    data['total_current_liabilities'] = data['Text80'];
    
    // Text83: Net current assets
    final text79 = _parseCurrency(data['Text79']);
    final text80 = _parseCurrency(data['Text80']);
    data['Text83'] = AuditFieldMap.formatCurrency(text79 - text80);
    data['net_current_assets'] = data['Text83'];
    
    // Text88: Total assets
    data['Text88'] = data['Text83'];
    data['total_assets'] = data['Text88'];
    
    // total_disbursements_sum
    data['total_disbursements_sum'] = data['Text80'];
    data['Text103'] = data['total_disbursements_sum'];
    
    print('DEBUG CALCULATED TOTALS:');
    print('Text72 (Net council): ${data['Text72']}');
    print('Text79 (Total current assets): ${data['Text79']}');
    print('Text80 (Total current liabilities): ${data['Text80']}');
    print('Text83 (Net current assets): ${data['Text83']}');
    print('Text88 (Total assets): ${data['Text88']}');
    print('Text103 (Total disbursements): ${data['Text103']}');
  }

  double _parseCurrency(String? value) {
    if (value == null) return 0.0;
    // Remove currency symbols and commas
    final cleanValue = value.replaceAll(RegExp(r'[^\d.-]'), '');
    return double.tryParse(cleanValue) ?? 0.0;
  }

  /// Save the current audit form data as a draft in Firestore
  Future<void> saveDraft(String period, int year, Map<String, String> formData) async {
    // This method would need to be updated to use the new service structure
    // For now, we'll leave it as a placeholder
    AppLogger.info('Draft saving not yet implemented with new service structure');
  }

  /// Load a saved audit draft from Firestore, if it exists
  Future<Map<String, String>?> loadDraft(String period, int year) async {
    // This method would need to be updated to use the new service structure
    // For now, we'll leave it as a placeholder
    AppLogger.info('Draft loading not yet implemented with new service structure');
    return null;
  }
} 