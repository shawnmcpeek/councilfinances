import 'package:flutter/services.dart';
import '../utils/logger.dart';

/// Manages PDF templates and their field mappings
class PdfTemplateManager {
  static final PdfTemplateManager _instance = PdfTemplateManager._internal();
  factory PdfTemplateManager() => _instance;
  PdfTemplateManager._internal();

  final Map<String, PdfTemplate> _templates = {};

  /// Register a template with its field mappings
  void registerTemplate(String templateId, String templatePath, Map<String, String> fieldMappings) {
    _templates[templateId] = PdfTemplate(
      id: templateId,
      path: templatePath,
      fieldMappings: fieldMappings,
    );
    AppLogger.debug('Registered template: $templateId');
  }

  /// Get a template by ID
  PdfTemplate? getTemplate(String templateId) {
    return _templates[templateId];
  }

  /// Load a template's PDF bytes
  Future<List<int>> loadTemplateBytes(String templateId) async {
    final template = _templates[templateId];
    if (template == null) {
      throw Exception('Template not found: $templateId');
    }

    try {
      final ByteData data = await rootBundle.load('forms/${template.path}');
      return data.buffer.asUint8List();
    } catch (e) {
      AppLogger.error('Error loading template: $templateId', e);
      rethrow;
    }
  }

  /// Map data fields to template fields
  Map<String, dynamic> mapDataToTemplateFields(String templateId, Map<String, dynamic> data) {
    final template = _templates[templateId];
    if (template == null) {
      throw Exception('Template not found: $templateId');
    }

    final Map<String, dynamic> mappedData = {};
    template.fieldMappings.forEach((templateField, dataField) {
      if (data.containsKey(dataField)) {
        mappedData[templateField] = data[dataField];
      }
    });

    return mappedData;
  }
}

/// Represents a PDF template with its field mappings
class PdfTemplate {
  final String id;
  final String path;
  final Map<String, String> fieldMappings;

  const PdfTemplate({
    required this.id,
    required this.path,
    required this.fieldMappings,
  });
}

/// Predefined template IDs
class TemplateIds {
  static const String form1728 = 'form1728';
  static const String auditReport = 'audit_report';
  static const String volunteerHours = 'volunteer_hours';
  static const String individualSurvey = 'individual_survey';
}

/// Initialize templates with their field mappings
void initializeTemplates() {
  final manager = PdfTemplateManager();

  // Form 1728 template (fraternal survey)
  manager.registerTemplate(
    TemplateIds.form1728,
    'fraternal_survey1728_p.pdf',
    {
      // Header fields
      'Text1': 'year_start',
      'Text2': 'year_end',
      'Text3': 'council_number',
      'Text4': 'jurisdiction',
      // ... Add all other field mappings from Form1728FieldMap
    },
  );

  // Individual Survey template
  manager.registerTemplate(
    TemplateIds.individualSurvey,
    'individual_survey1728a_p.pdf',
    {
      // Year field (same value in both fields)
      'Text1': 'report_year',
      'undefined': 'report_year',  // Same as Text1, gets last 2 digits of year

      // Council Fields (Text2-Text41)
      'Text2': 'council_activity_1',
      'Text3': 'council_activity_2',
      'Text4': 'council_activity_3',
      'Text5': 'council_activity_4',
      'Text6': 'council_activity_5',
      'Text7': 'council_activity_6',
      'Text8': 'council_activity_7',
      'Text9': 'council_activity_8',
      'Text11': 'council_activity_9',
      'Text12': 'council_activity_10',
      'Text13': 'council_activity_11',
      'Text14': 'council_activity_12',
      'Text15': 'council_activity_13',
      'Text16': 'council_activity_14',
      'Text17': 'council_activity_15',
      'Text18': 'council_activity_16',
      'Text19': 'council_activity_17',
      'Text20': 'council_activity_18',
      'Text21': 'council_activity_19',
      'Text22': 'council_activity_20',
      'Text23': 'council_activity_21',
      'Text24': 'council_activity_22',
      'Text25': 'council_activity_23',
      'Text26': 'council_activity_24',
      'Text27': 'council_activity_25',
      'Text28': 'council_activity_26',
      'Text29': 'council_activity_27',
      'Text30': 'council_activity_28',
      'Text31': 'council_activity_29',
      'Text32': 'council_activity_30',
      'Text33': 'council_activity_31',
      'Text34': 'council_activity_32',
      'Text35': 'council_activity_33',
      'Text36': 'council_activity_34',
      'Text37': 'council_activity_35',
      'Text38': 'council_activity_36',
      'Text39': 'council_activity_37',
      'Text41': 'council_activity_38',
      'TOTAL': 'council_total',  // Sum of Text2-Text41

      // Assembly Fields (Text42-Text79)
      'Text42': 'assembly_activity_1',
      'Text43': 'assembly_activity_2',
      'Text44': 'assembly_activity_3',
      'Text45': 'assembly_activity_4',
      'Text46': 'assembly_activity_5',
      'Text47': 'assembly_activity_6',
      'Text48': 'assembly_activity_7',
      'Text49': 'assembly_activity_8',
      'Text50': 'assembly_activity_9',
      'Text51': 'assembly_activity_10',
      'Text52': 'assembly_activity_11',
      'Text53': 'assembly_activity_12',
      'Text54': 'assembly_activity_13',
      'Text55': 'assembly_activity_14',
      'Text56': 'assembly_activity_15',
      'Text57': 'assembly_activity_16',
      'Text58': 'assembly_activity_17',
      'Text59': 'assembly_activity_18',
      'Text60': 'assembly_activity_19',
      'Text61': 'assembly_activity_20',
      'Text62': 'assembly_activity_21',
      'Text63': 'assembly_activity_22',
      'Text64': 'assembly_activity_23',
      'Text65': 'assembly_activity_24',
      'Text66': 'assembly_activity_25',
      'Text67': 'assembly_activity_26',
      'Text68': 'assembly_activity_27',
      'Text69': 'assembly_activity_28',
      'Text70': 'assembly_activity_29',
      'Text71': 'assembly_activity_30',
      'Text72': 'assembly_activity_31',
      'Text73': 'assembly_activity_32',
      'Text74': 'assembly_activity_33',
      'Text75': 'assembly_activity_34',
      'Text76': 'assembly_activity_35',
      'Text77': 'assembly_activity_36',
      'Text78': 'assembly_activity_37',
      'Text79': 'assembly_activity_38',
      'TOTAL_2': 'assembly_total',  // Sum of Text42-Text79
    },
  );

  // Audit report template
  manager.registerTemplate(
    TemplateIds.auditReport,
    'audit2_1295_p.pdf',
    {
      // Basic Info
      'Text1': 'council_number',
      'Text2': 'council_city',
      'Text3': 'year',
      'Text4': 'organization_name',

      // Income Section
      'Text50': 'manual_income_1',
      'Text51': 'membership_dues',
      'Text52': 'top_program_1_name',
      'Text53': 'top_program_1_amount',
      'Text54': 'top_program_2_name',
      'Text55': 'top_program_2_amount',
      'Text56': 'other_programs_name',
      'Text57': 'other_programs_amount',
      'Text58': 'total_income',
      'Text59': 'manual_income_2',
      'Text60': 'cash_on_hand_end_period',

      // Treasurer Section
      'Text61': 'treasurer_cash_beginning',
      'Text62': 'treasurer_received_financial_secretary',
      'Text63': 'treasurer_transfers_from_savings',
      'Text64': 'treasurer_interest_earned',
      'Text65': 'treasurer_total_receipts',
      'Text66': 'treasurer_supreme_per_capita',
      'Text67': 'treasurer_state_per_capita',
      'Text68': 'treasurer_general_council_expenses',
      'Text69': 'treasurer_transfers_to_savings',
      'Text70': 'treasurer_miscellaneous',
      'Text71': 'treasurer_total_disbursements',
      'Text72': 'treasurer_net_balance',
      'Text73': 'net_council_verify',

      // Membership Section
      'Text74': 'manual_membership_1',
      'Text75': 'manual_membership_2',
      'Text76': 'manual_membership_3',
      'Text77': 'membership_count',
      'Text78': 'membership_dues_total',
      'Text79': 'total_membership',
      'Text80': 'total_disbursements',
      'Text83': 'net_membership',

      // Disbursements Section
      'Text84': 'manual_disbursement_1',
      'Text85': 'manual_disbursement_2',
      'Text86': 'manual_disbursement_3',
      'Text87': 'manual_disbursement_4',
      'Text88': 'total_disbursements_verify',

      // Additional Fields
      'Text89': 'manual_field_1',
      'Text90': 'manual_field_2',
      'Text91': 'manual_field_3',
      'Text92': 'manual_field_4',
      'Text93': 'manual_field_5',
      'Text95': 'manual_field_6',
      'Text96': 'manual_field_7',
      'Text97': 'manual_field_8',
      'Text98': 'manual_field_9',
      'Text99': 'manual_field_10',
      'Text100': 'manual_field_11',
      'Text101': 'manual_field_12',
      'Text102': 'manual_field_13',
      'Text103': 'total_disbursements_sum',
      'Text104': 'manual_field_14',
      'Text105': 'manual_field_15',
      'Text106': 'manual_field_16',
      'Text107': 'manual_field_17',
      'Text108': 'manual_field_18',
      'Text109': 'manual_field_19',
      'Text110': 'manual_field_20',
    },
  );

  // Volunteer hours template (no template file, uses generateNewPdf)
  manager.registerTemplate(
    TemplateIds.volunteerHours,
    '',  // No template file
    {},  // No field mappings
  );
} 