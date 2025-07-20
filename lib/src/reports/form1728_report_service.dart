import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';
import '../services/user_service.dart';
import 'base_pdf_report_service.dart';
import 'pdf_template_manager.dart';

class Form1728ReportService extends BasePdfReportService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();
  final PdfTemplateManager _templateManager = PdfTemplateManager();

  @override
  String get templatePath => 'fraternal_survey1728_p.pdf';

  Future<Map<String, dynamic>> aggregateProgramData(String organizationId, String year) async {
    final template = _templateManager.getTemplate(TemplateIds.form1728);
    if (template == null) {
      throw Exception('Form 1728 template not found');
    }

    final Map<String, dynamic> totals = {
      // Initialize all fields from our mapping
      for (var value in template.fieldMappings.values)
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
        final response = await _supabase
            .from('programs')
            .select()
            .eq('organizationId', organizationId)
            .eq('year', year)
            .eq('category', category);

        for (final data in response) {
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

  /// Generate a Form 1728 report for the given organization and year
  Future<void> generateForm1728Report(String organizationId, String year) async {
    try {
      // 1. Aggregate the data
      final data = await aggregateProgramData(organizationId, year);
      AppLogger.debug('Starting PDF generation with data: $data');

      // 2. Map data to template fields
      final mappedData = _templateManager.mapDataToTemplateFields(TemplateIds.form1728, data);

      // 3. Generate the PDF using the base service
      final fileName = 'Form1728P_${organizationId}_$year.pdf';
      await super.generateReport(mappedData, fileName, 'Form 1728P Report for $year');
      
      AppLogger.debug('Form 1728 report generated for $year');
    } catch (e, stackTrace) {
      AppLogger.error('Error generating Form 1728 report', e, stackTrace);
      rethrow;
    }
  }
} 