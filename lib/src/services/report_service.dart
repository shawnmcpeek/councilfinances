import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../utils/logger.dart';
import 'package:share_plus/share_plus.dart';
import '../services/user_service.dart';

class Form1728FieldMap {
  // Map field IDs to their corresponding data points
  static const Map<String, String> fields = {
    // Header fields
    'Text1': 'year_start',  // First year field in header
    'Text2': 'year_end',    // Second year field in header
    'Text3': 'council_number',
    'Text4': 'jurisdiction',

    // Faith Activities
    'Text5': 'faith_vocations_disbursement',
    'Text6': 'faith_vocations_hours',
    'Text7': 'faith_facilities_disbursement',
    'Text8': 'faith_facilities_hours',
    'Text9': 'faith_schools_disbursement',
    'Text10': 'faith_schools_hours',
    'Text11': 'faith_education_disbursement',
    'Text12': 'faith_education_hours',
    'Text13': 'faith_prayer_disbursement',
    'Text14': 'faith_prayer_hours',
    'Text15': 'faith_gifts_disbursement',
    'Text16': 'faith_gifts_hours',
    'Text17': 'faith_misc_disbursement',
    'Text18': 'faith_misc_hours',
    'Text19': 'faith_total_disbursement',
    'Text20': 'faith_total_hours',

    // Family Activities
    'Text21': 'family_food_disbursement',
    'Text22': 'family_food_hours',
    'Text23': 'family_formation_disbursement',
    'Text24': 'family_formation_hours',
    'Text25': 'family_christmas_disbursement',
    'Text26': 'family_christmas_hours',
    'Text27': 'family_week_disbursement',
    'Text28': 'family_week_hours',
    'Text29': 'family_prayer_disbursement',
    'Text30': 'family_prayer_hours',
    'Text31': 'family_misc_disbursement',
    'Text32': 'family_misc_hours',
    'Text33': 'family_total_disbursement',
    'Text34': 'family_total_hours',

    // Community Activities
    'Text35': 'community_coats_disbursement',
    'Text36': 'community_coats_hours',
    'Text37': 'community_wheelchair_disbursement',
    'Text38': 'community_wheelchair_hours',
    'Text39': 'community_habitat_disbursement',
    'Text40': 'community_habitat_hours',
    'Text41': 'community_disaster_disbursement',
    'Text42': 'community_disaster_hours',
    'Text43': 'community_disabilities_disbursement',
    'Text44': 'community_disabilities_hours',
    'Text45': 'community_elderly_disbursement',
    'Text46': 'community_elderly_hours',
    'Text47': 'community_health_disbursement',
    'Text48': 'community_health_hours',
    'Text49': 'community_squires_disbursement',
    'Text50': 'community_squires_hours',
    'Text51': 'community_youth_disbursement',
    'Text52': 'community_youth_hours',
    'Text53': 'community_athletics_disbursement',
    'Text54': 'community_athletics_hours',
    'Text55': 'community_welfare_disbursement',
    'Text56': 'community_welfare_hours',
    'Text57': 'community_scholarships_disbursement',
    'Text58': 'community_scholarships_hours',
    'Text59': 'community_veterans_disbursement',
    'Text60': 'community_veterans_hours',
    'Text61': 'community_misc_disbursement',
    'Text62': 'community_misc_hours',
    'Text63': 'community_total_disbursement',
    'Text64': 'community_total_hours',

    // Life Activities
    'Text65': 'life_olympics_disbursement',
    'Text66': 'life_olympics_hours',
    'Text67': 'life_marches_disbursement',
    'Text68': 'life_marches_hours',
    'Text69': 'life_ultrasound_disbursement',
    'Text70': 'life_ultrasound_hours',
    'Text71': 'life_pregnancy_disbursement',
    'Text72': 'life_pregnancy_hours',
    'Text73': 'life_refugee_disbursement',
    'Text74': 'life_refugee_hours',
    'Text75': 'life_memorials_disbursement',
    'Text76': 'life_memorials_hours',
    'Text77': 'life_misc_disbursement',
    'Text78': 'life_misc_hours',
    'Text79': 'life_total_disbursement',
    'Text80': 'life_total_hours',

    // Grand Totals
    'Text81': 'total_disbursement',
    'Text82': 'total_hours',

    // Meetings Section
    'Text83': 'meetings_regular',
    'Text84': 'meetings_social',
    'Text85': 'meetings_special',
    'Text86': 'meetings_total',

    // Other Fraternal Commitments
    'Text87': 'visits_sick',
    'Text88': 'visits_bereaved',
    'Text89': 'blood_donations',
    'Text90': 'masses_for_members',
    'Text91': 'hours_fraternal_service',

    // Signature Fields
    'Text92': 'grand_knight_name',
    'Text93': 'gk_date',  // Date field format
    'Text94': 'fs_member_number',
    'Text95': 'financial_secretary_name',
    'Text96': 'fs_date',  // Date field format
    'Text97': 'member_number'
  };
}

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  Future<Map<String, dynamic>> aggregateProgramData(String organizationId, String year) async {
    final Map<String, dynamic> totals = {
      // Initialize all fields from our mapping
      for (var value in Form1728FieldMap.fields.values)
        value: value.contains('disbursement') ? 0.0 : 0,
    };

    try {
      // Set basic information
      totals['year_start'] = year;
      totals['year_end'] = year;
      
      // Extract council/assembly number from organizationId
      final orgNumber = organizationId.substring(1);
      totals['council_number'] = orgNumber.trim();

      // Get jurisdiction from user profile
      final userProfile = await _userService.getUserProfile();
      totals['jurisdiction'] = userProfile?.jurisdiction ?? 'TN';

      // Get all categories
      final categories = ['faith', 'family', 'community', 'life'];
      
      for (final category in categories) {
        final QuerySnapshot snapshot = await _db
            .collection('organizations')
            .doc(organizationId)
            .collection('program_entries')
            .doc(year)
            .collection(category)
            .get();

        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final programId = data['programId'] as String;
          final hours = data['hours'] as int? ?? 0;
          final disbursement = (data['disbursement'] as num?)?.toDouble() ?? 0.0;

          // Update specific program totals based on programId mapping
          final String mappedProgram = _mapProgramIdToFormField(category, programId);
          if (mappedProgram.isNotEmpty) {
            final hoursKey = '${mappedProgram}_hours';
            final disbursementKey = '${mappedProgram}_disbursement';
            totals[hoursKey] = (totals[hoursKey] ?? 0) + hours;
            totals[disbursementKey] = (totals[disbursementKey] ?? 0.0) + disbursement;
          } else {
            // If no specific mapping, add to misc
            final hoursKey = '${category}_misc_hours';
            final disbursementKey = '${category}_misc_disbursement';
            totals[hoursKey] = (totals[hoursKey] ?? 0) + hours;
            totals[disbursementKey] = (totals[disbursementKey] ?? 0.0) + disbursement;
          }

          // Update category totals
          totals['${category}_total_hours'] = (totals['${category}_total_hours'] ?? 0) + hours;
          totals['${category}_total_disbursement'] = (totals['${category}_total_disbursement'] ?? 0.0) + disbursement;

          // Update grand totals
          totals['total_hours'] = (totals['total_hours'] ?? 0) + hours;
          totals['total_disbursement'] = (totals['total_disbursement'] ?? 0.0) + disbursement;
        }
      }

      AppLogger.debug('Aggregated program data for $year: $totals');
      return totals;
    } catch (e, stackTrace) {
      AppLogger.error('Error aggregating program data', e, stackTrace);
      rethrow;
    }
  }

  String _mapProgramIdToFormField(String category, String programId) {
    // Map program IDs to their corresponding form fields
    final Map<String, String> programMapping = {
      // Faith Activities
      'vocations': 'faith_vocations',
      'facilities': 'faith_facilities',
      'schools': 'faith_schools',
      'education': 'faith_education',
      'prayer': 'faith_prayer',
      'gifts': 'faith_gifts',

      // Family Activities
      'food': 'family_food',
      'formation': 'family_formation',
      'christmas': 'family_christmas',
      'week': 'family_week',
      'prayer_night': 'family_prayer',

      // Community Activities
      'coats': 'community_coats',
      'wheelchair': 'community_wheelchair',
      'habitat': 'community_habitat',
      'disaster': 'community_disaster',
      'disabilities': 'community_disabilities',
      'elderly': 'community_elderly',
      'health': 'community_health',
      'squires': 'community_squires',
      'youth': 'community_youth',
      'athletics': 'community_athletics',
      'welfare': 'community_welfare',
      'scholarships': 'community_scholarships',
      'veterans': 'community_veterans',

      // Life Activities
      'olympics': 'life_olympics',
      'marches': 'life_marches',
      'ultrasound': 'life_ultrasound',
      'pregnancy': 'life_pregnancy',
      'refugee': 'life_refugee',
      'memorials': 'life_memorials',
    };

    return programMapping[programId] ?? '';
  }

  Future<void> generateForm1728Report(String organizationId, String year) async {
    try {
      // 1. Aggregate the data
      final totals = await aggregateProgramData(organizationId, year);
      AppLogger.debug('Starting PDF generation with data: $totals');

      // 2. Load the PDF template
      final ByteData templateData = await rootBundle.load('assets/forms/fraternal_survey1728_p.pdf');
      AppLogger.debug('Loaded PDF template');
      
      final List<int> bytes = templateData.buffer.asUint8List();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfForm form = document.form;
      AppLogger.debug('Created PDF document and form');

      // 3. Fill the form fields
      Form1728FieldMap.fields.forEach((pdfField, dataKey) {
        try {
          // Convert field name to index by removing 'Text' prefix
          final fieldIndex = int.tryParse(pdfField.replaceAll('Text', ''));
          if (fieldIndex != null && fieldIndex > 0 && fieldIndex <= form.fields.count) {
            final field = form.fields[fieldIndex - 1] as PdfTextBoxField?;
            if (field != null) {
              var value = totals[dataKey];
              AppLogger.debug('Setting field $pdfField ($dataKey) to value: $value');
              
              // Format the value based on field type
              if (value is double) {
                field.text = value > 0 ? '\$${value.toStringAsFixed(2)}' : '';
              } else if (value is int) {
                field.text = value > 0 ? value.toString() : '';
              } else if (value is String) {
                field.text = value;
              }
            } else {
              AppLogger.debug('Field $pdfField not found as PdfTextBoxField');
            }
          } else {
            AppLogger.debug('Invalid field index for $pdfField');
          }
        } catch (e) {
          AppLogger.error('Error setting field $pdfField', e);
        }
      });

      // 4. Generate the filled PDF bytes
      final List<int> pdfBytes = await document.save();
      document.dispose();
      AppLogger.debug('Generated PDF bytes');

      // 5. Share the PDF bytes directly
      final String fileName = 'Form1728P_${organizationId}_$year.pdf';
      final XFile pdfXFile = XFile.fromData(
        Uint8List.fromList(pdfBytes),
        name: fileName,
        mimeType: 'application/pdf',
      );
      
      await Share.shareXFiles(
        [pdfXFile],
        subject: 'Form 1728P Report for $year',
      );

      AppLogger.debug('Shared Form 1728 report for $year');
    } catch (e, stackTrace) {
      AppLogger.error('Error generating Form 1728 report', e, stackTrace);
      rethrow;
    }
  }
} 