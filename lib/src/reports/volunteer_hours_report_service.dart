import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../services/user_service.dart';
import '../utils/logger.dart';
import '../services/report_service.dart';

class VolunteerHoursReportService {
  final UserService _userService;
  final FirebaseFirestore _firestore;
  final ReportService _reportService = ReportService();

  VolunteerHoursReportService(this._userService, this._firestore);

  Future<void> generateReport(String userId, String year, String organizationId) async {
    try {
      AppLogger.info('Generating volunteer hours report for user $userId for year $year');
      
      // Get user profile for organization info
      final userProfile = await _userService.getUserProfileById(userId);
      if (userProfile == null) {
        AppLogger.error('User profile not found for ID: $userId');
        throw Exception('User profile not found');
      }

      // Query hours for the specified year
      final startDate = DateTime(int.parse(year), 1, 1);
      final endDate = DateTime(int.parse(year), 12, 31);
      
      AppLogger.debug('Querying hours between $startDate and $endDate for organization $organizationId');
      
      final hoursQuery = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('hours')
          .where('userId', isEqualTo: userId)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // Group hours by program
      final Map<String, double> programHours = {};
      double totalHours = 0;

      for (var doc in hoursQuery.docs) {
        final data = doc.data();
        final program = data['programName'] as String;
        final hours = data['totalHours'] as num;
        
        programHours[program] = (programHours[program] ?? 0) + hours.toDouble();
        totalHours += hours.toDouble();
      }

      AppLogger.debug('Program hours: $programHours');
      AppLogger.debug('Total hours: $totalHours');

      // Create PDF document
      final document = PdfDocument();
      final page = document.pages.add();

      // Draw report header
      page.graphics.drawString(
        'Volunteer Hours Report',
        PdfStandardFont(PdfFontFamily.helvetica, 24),
        bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, 50),
        format: PdfStringFormat(alignment: PdfTextAlignment.center)
      );

      // Draw organization and year
      page.graphics.drawString(
        'Organization: $organizationId',
        PdfStandardFont(PdfFontFamily.helvetica, 12),
        bounds: Rect.fromLTWH(0, 60, page.getClientSize().width, 20)
      );

      page.graphics.drawString(
        'Year: $year',
        PdfStandardFont(PdfFontFamily.helvetica, 12),
        bounds: Rect.fromLTWH(0, 80, page.getClientSize().width, 20)
      );

      // Draw program hours table
      var yOffset = 120.0;
      page.graphics.drawString(
        'Program Hours:',
        PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(0, yOffset, page.getClientSize().width, 20)
      );

      yOffset += 30;
      for (var entry in programHours.entries) {
        page.graphics.drawString(
          '${entry.key}: ${entry.value.toStringAsFixed(1)} hours',
          PdfStandardFont(PdfFontFamily.helvetica, 12),
          bounds: Rect.fromLTWH(20, yOffset, page.getClientSize().width - 40, 20)
        );
        yOffset += 20;
      }

      // Draw total hours
      yOffset += 20;
      page.graphics.drawString(
        'Total Hours: ${totalHours.toStringAsFixed(1)}',
        PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(0, yOffset, page.getClientSize().width, 20)
      );

      // Save and share the document
      final List<int> bytes = await document.save();
      document.dispose();

      final fileName = 'volunteer_hours_${organizationId}_$year.pdf';
      await _reportService.saveOrShareFile(
        bytes,
        fileName,
        'Volunteer Hours Report for $year'
      );

      AppLogger.info('Report generated and saved/shared successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error generating volunteer hours report', e, stackTrace);
      rethrow;
    }
  }
} 