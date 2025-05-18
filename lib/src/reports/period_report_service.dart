
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../utils/logger.dart';
import '../services/report_file_saver.dart';

class PeriodReportService {
  static const String _decemberReportTemplate = 'audit2_1295_p.pdf';
  static const String _juneReportTemplate = 'audit2_1295_p.pdf'; // Using same template for now

  Future<void> generateReport(String period, int year) async {
    try {
      AppLogger.info('Generating period report for $period $year');

      // 1. Load the PDF template
      final ByteData templateData = await rootBundle.load('assets/forms/$_decemberReportTemplate');
      AppLogger.debug('Loaded PDF template');
      
      final List<int> bytes = templateData.buffer.asUint8List();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfForm form = document.form;
      AppLogger.debug('Created PDF document and form');

      // 2. Get report data
      final data = await _getReportData(period, year);
      AppLogger.debug('Got report data: $data');

      // 3. Fill the form fields
      data.forEach((fieldName, value) {
        try {
          final fieldIndex = int.tryParse(fieldName.replaceAll('Text', ''));
          if (fieldIndex != null && fieldIndex > 0 && fieldIndex <= form.fields.count) {
            final field = form.fields[fieldIndex - 1] as PdfTextBoxField?;
            if (field != null) {
              field.text = value.toString();
              AppLogger.debug('Set field $fieldName to $value');
            } else {
              AppLogger.debug('Field $fieldName not found as PdfTextBoxField');
            }
          } else {
            AppLogger.debug('Invalid field index for $fieldName');
          }
        } catch (e) {
          AppLogger.error('Error setting field $fieldName', e);
        }
      });

      // 4. Generate the filled PDF bytes
      final List<int> pdfBytes = await document.save();
      document.dispose();
      AppLogger.debug('Generated PDF bytes');

      // 5. Save or share the PDF using platform-specific implementation
      final String fileName = 'audit_report_${period.toLowerCase()}_$year.pdf';
      await saveOrShareFile(pdfBytes, fileName, 'Audit Report for $period $year');

      AppLogger.info('Period report saved/shared successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error generating period report', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _getReportData(String period, int year) async {
    // TODO: Implement actual data collection from Firestore
    // For now, return placeholder data
    return {
      'Text1': 'Sample Council',
      'Text2': '31', // Day
      'Text3': period, // Month
      'Text4': year.toString(), // Year
      // Add more fields as needed
    };
  }
} 