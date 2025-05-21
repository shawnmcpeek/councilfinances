import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../utils/logger.dart';
import '../services/report_file_saver.dart';

abstract class BasePdfReportService {
  /// The template file path relative to assets/forms/
  String get templatePath;

  /// Generate a PDF report with the given data
  Future<void> generateReport(Map<String, dynamic> data, String fileName, String reportTitle) async {
    try {
      AppLogger.info('Generating PDF report: $fileName');

      // 1. Load the PDF template
      final ByteData templateData = await rootBundle.load('forms/$templatePath');
      AppLogger.debug('Loaded PDF template');
      
      final List<int> bytes = templateData.buffer.asUint8List();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfForm form = document.form;
      AppLogger.debug('Created PDF document and form');

      // 2. Fill the form fields
      await fillFormFields(form, data);
      AppLogger.debug('Filled form fields');

      // 3. Generate the filled PDF bytes
      final List<int> pdfBytes = await document.save();
      document.dispose();
      AppLogger.debug('Generated PDF bytes');

      // 4. Save or share the PDF
      await saveOrShareFile(pdfBytes, fileName, reportTitle);
      AppLogger.info('Report saved/shared successfully: $fileName');
    } catch (e, stackTrace) {
      AppLogger.error('Error generating PDF report', e, stackTrace);
      rethrow;
    }
  }

  /// Fill form fields with data. Override this method to implement custom field filling logic.
  Future<void> fillFormFields(PdfForm form, Map<String, dynamic> data) async {
    for (var i = 0; i < form.fields.count; i++) {
      final field = form.fields[i];
      if (field is PdfTextBoxField) {
        final fieldName = field.name;
        if (data.containsKey(fieldName)) {
          field.text = data[fieldName].toString();
          AppLogger.debug('Set field $fieldName to ${data[fieldName]}');
        }
      }
    }
  }

  /// Create a new PDF document from scratch (for reports without templates)
  Future<void> generateNewPdf(Map<String, dynamic> data, String fileName, String reportTitle) async {
    try {
      AppLogger.info('Generating new PDF report: $fileName');

      // 1. Create a new PDF document
      final document = PdfDocument();
      final page = document.pages.add();

      // 2. Draw the report content
      await drawReportContent(page, data);
      AppLogger.debug('Drew report content');

      // 3. Generate the PDF bytes
      final List<int> pdfBytes = await document.save();
      document.dispose();
      AppLogger.debug('Generated PDF bytes');

      // 4. Save or share the PDF
      await saveOrShareFile(pdfBytes, fileName, reportTitle);
      AppLogger.info('Report saved/shared successfully: $fileName');
    } catch (e, stackTrace) {
      AppLogger.error('Error generating new PDF report', e, stackTrace);
      rethrow;
    }
  }

  /// Draw report content on a page. Override this method to implement custom drawing logic.
  Future<void> drawReportContent(PdfPage page, Map<String, dynamic> data) async {
    // Default implementation draws a title
    page.graphics.drawString(
      data['title'] ?? 'Report',
      PdfStandardFont(PdfFontFamily.helvetica, 24),
      bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, 50),
      format: PdfStringFormat(alignment: PdfTextAlignment.center)
    );
  }
} 