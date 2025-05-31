import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/hours_entry.dart';
import '../services/user_service.dart';
import '../utils/logger.dart';
import '../services/report_file_saver.dart' show saveOrShareFile;

class IndividualSurveyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();
  static const String _fillIndividualSurveyUrl = 'https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/fillIndividualSurveyReport';

  Future<Map<String, dynamic>> aggregateHoursData(String userId, String reportYear) async {
    try {
      // Set the report year (last 2 digits)
      final yearDigits = reportYear.substring(reportYear.length - 2);
      final Map<String, dynamic> totals = {
        'year': reportYear,
        'report_year': yearDigits,
      };

      // Query hours for the specified year
      final startDate = DateTime(int.parse(reportYear), 1, 1);
      final endDate = DateTime(int.parse(reportYear), 12, 31);

      // Get user profile to determine organizations
      final userProfile = await _userService.getUserProfileById(userId);
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      // Initialize council and assembly totals
      double councilTotal = 0;
      double assemblyTotal = 0;

      // Get council hours
      if (userProfile.councilNumber != null) {
        final councilHours = await _getHoursForOrganization(
          'C${userProfile.councilNumber.toString().padLeft(6, '0')}',
          userId,
          startDate,
          endDate,
          false,
        );
        councilTotal = _aggregateHoursByCategory(councilHours, totals, false);
      }

      // Get assembly hours
      if (userProfile.assemblyNumber != null) {
        final assemblyHours = await _getHoursForOrganization(
          'A${userProfile.assemblyNumber.toString().padLeft(6, '0')}',
          userId,
          startDate,
          endDate,
          true,
        );
        assemblyTotal = _aggregateHoursByCategory(assemblyHours, totals, true);
      }

      // Set the totals
      totals['council_total'] = councilTotal;
      totals['assembly_total'] = assemblyTotal;

      AppLogger.debug('Aggregated hours data for report year $reportYear: $totals');
      return totals;
    } catch (e, stackTrace) {
      AppLogger.error('Error aggregating hours data for report year $reportYear', e, stackTrace);
      rethrow;
    }
  }

  Future<List<HoursEntry>> _getHoursForOrganization(
    String organizationId,
    String userId,
    DateTime startDate,
    DateTime endDate,
    bool isAssembly,
  ) async {
    final snapshot = await _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('hours')
        .where('userId', isEqualTo: userId)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('startTime', isLessThan: Timestamp.fromDate(endDate))
        .where('isAssembly', isEqualTo: isAssembly)
        .get();

    return snapshot.docs
        .map((doc) => HoursEntry.fromFirestore(doc))
        .toList();
  }

  double _aggregateHoursByCategory(List<HoursEntry> entries, Map<String, dynamic> totals, bool isAssembly) {
    double total = 0;
    final expectedPrefix = isAssembly ? 'AP' : 'CP';
    final activityPrefix = isAssembly ? 'assembly_activity_' : 'council_activity_';

    for (final entry in entries) {
      // Validate program ID format (CP001 or AP001)
      if (!entry.programId.startsWith(expectedPrefix)) {
        AppLogger.warning('Invalid program ID format for ${isAssembly ? "assembly" : "council"}: ${entry.programId}');
        continue;
      }

      // Get the program number (1-38) from the program ID
      final programNumber = int.parse(entry.programId.substring(2));
      if (programNumber < 1 || programNumber > 38) {
        AppLogger.warning('Invalid program number: ${entry.programId}');
        continue;
      }

      // Add hours to the appropriate activity field
      final activityKey = '${activityPrefix}${programNumber}';
      totals[activityKey] = (totals[activityKey] ?? 0) + entry.totalHours;
      total += entry.totalHours;

      AppLogger.debug('Mapped ${entry.programId} hours to $activityKey: ${entry.totalHours}');
    }

    return total;
  }

  Future<void> generateIndividualSurvey(String userId, String year) async {
    try {
      // 1. Aggregate the data
      final data = await aggregateHoursData(userId, year);
      AppLogger.debug('Starting PDF generation with data: $data');

      // 2. Call Firebase Function to fill the PDF
      final response = await http.post(
        Uri.parse(_fillIndividualSurveyUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to generate PDF: ${response.body}');
      }

      // 3. Save or share the PDF
      final fileName = 'individual_survey_${userId}_$year.pdf';
      await saveOrShareFile(
        response.bodyBytes,
        fileName,
        'Individual Survey for $year'
      );

      AppLogger.info('Individual survey generated successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error generating individual survey', e, stackTrace);
      rethrow;
    }
  }
} 