import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:ui';
import '../models/budget_entry.dart';
import '../services/report_file_saver.dart';
import '../utils/logger.dart';

class AnnualBudgetReportService {
  Future<void> generateAnnualBudgetReport({
    required String organizationId,
    required String year,
    required List<BudgetEntry> entries,
    required String status,
  }) async {
    try {
      final document = PdfDocument();
      final page = document.pages.add();
      final graphics = page.graphics;
      final width = page.getClientSize().width;
      double y = 0;

      // Title
      graphics.drawString(
        'Annual Budget Report',
        PdfStandardFont(PdfFontFamily.helvetica, 24, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(0, y, width, 40),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      y += 40;

      // Organization and year (formatted)
      String orgType = organizationId.startsWith('A') ? 'Assembly' : 'Council';
      String orgNumber = organizationId.replaceAll(RegExp(r'^[CA]0*'), '');
      graphics.drawString(
        'Organization: $orgType $orgNumber',
        PdfStandardFont(PdfFontFamily.helvetica, 12),
        bounds: Rect.fromLTWH(0, y, width, 20),
      );
      y += 20;
      graphics.drawString(
        'Year: $year',
        PdfStandardFont(PdfFontFamily.helvetica, 12),
        bounds: Rect.fromLTWH(0, y, width, 20),
      );
      y += 30;

      // Table headers
      final headerFont = PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold);
      final cellFont = PdfStandardFont(PdfFontFamily.helvetica, 12);
      final colWidths = [width * 0.40, width * 0.20, width * 0.20, width * 0.20];
      final headers = ['Program', 'Income', 'Expenses', 'Total'];
      double x = 0;
      for (int i = 0; i < headers.length; i++) {
        graphics.drawString(
          headers[i],
          headerFont,
          bounds: Rect.fromLTWH(x, y, colWidths[i], 20),
        );
        x += colWidths[i];
      }
      y += 22;

      // Table rows
      double totalIncome = 0;
      double totalExpenses = 0;
      double totalNet = 0;
      for (final entry in entries) {
        x = 0;
        graphics.drawString(entry.programName, cellFont, bounds: Rect.fromLTWH(x, y, colWidths[0], 18));
        x += colWidths[0];
        graphics.drawString(entry.income.toStringAsFixed(2), cellFont, bounds: Rect.fromLTWH(x, y, colWidths[1], 18));
        x += colWidths[1];
        graphics.drawString(entry.expenses.toStringAsFixed(2), cellFont, bounds: Rect.fromLTWH(x, y, colWidths[2], 18));
        x += colWidths[2];
        final net = entry.income - entry.expenses;
        graphics.drawString(net.toStringAsFixed(2), cellFont, bounds: Rect.fromLTWH(x, y, colWidths[3], 18));
        y += 18;
        totalIncome += entry.income;
        totalExpenses += entry.expenses;
        totalNet += net;
      }

      // Totals row
      x = 0;
      graphics.drawString('TOTAL', headerFont, bounds: Rect.fromLTWH(x, y, colWidths[0], 20));
      x += colWidths[0];
      graphics.drawString(totalIncome.toStringAsFixed(2), headerFont, bounds: Rect.fromLTWH(x, y, colWidths[1], 20));
      x += colWidths[1];
      graphics.drawString(totalExpenses.toStringAsFixed(2), headerFont, bounds: Rect.fromLTWH(x, y, colWidths[2], 20));
      x += colWidths[2];
      graphics.drawString(totalNet.toStringAsFixed(2), headerFont, bounds: Rect.fromLTWH(x, y, colWidths[3], 20));

      // Save and share
      final pdfBytes = await document.save();
      document.dispose();
      final fileName = 'annual_budget_${organizationId}_$year.pdf';
      await saveOrShareFile(pdfBytes, fileName, 'Annual Budget Report for $year');
      AppLogger.info('Annual budget report generated and saved/shared successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error generating annual budget report', e, stackTrace);
      rethrow;
    }
  }
} 