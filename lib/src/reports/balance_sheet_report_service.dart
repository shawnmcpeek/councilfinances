import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../utils/logger.dart';
import 'base_pdf_report_service.dart';

class BalanceSheetReportService extends BasePdfReportService {
  final FirebaseFirestore _firestore;

  BalanceSheetReportService(this._firestore);

  @override
  String get templatePath => '';  // No template file, we generate from scratch

  Future<void> generateBalanceSheetReport(String organizationId, String year) async {
    try {
      AppLogger.info('Generating balance sheet report for organization $organizationId for year $year');
      
      // Get financial data for the organization
      final startDate = DateTime(int.parse(year), 1, 1);
      final endDate = DateTime(int.parse(year), 12, 31);
      
      // Query transactions for the specified year
      final transactionsSnapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // Calculate totals
      double totalAssets = 0;
      double totalLiabilities = 0;
      double totalEquity = 0;

      // Process transactions to calculate totals
      for (var doc in transactionsSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num).toDouble();
        final type = data['type'] as String;
        
        // Categorize transaction
        if (type == 'asset') {
          totalAssets += amount;
        } else if (type == 'liability') {
          totalLiabilities += amount;
        } else if (type == 'equity') {
          totalEquity += amount;
        }
      }

      // Prepare data for PDF generation
      final data = {
        'title': 'Balance Sheet',
        'organization': organizationId,
        'year': year,
        'total_assets': totalAssets,
        'total_liabilities': totalLiabilities,
        'total_equity': totalEquity,
      };

      // Generate the PDF
      final fileName = 'balance_sheet_${organizationId}_$year.pdf';
      await generateNewPdf(data, fileName, 'Balance Sheet for $year');

      AppLogger.info('Balance sheet report generated and saved/shared successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error generating balance sheet report', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> drawReportContent(PdfPage page, Map<String, dynamic> data) async {
    final title = data['title'] as String;
    final organization = data['organization'] as String;
    final year = data['year'] as String;
    final totalAssets = data['total_assets'] as double;
    final totalLiabilities = data['total_liabilities'] as double;
    final totalEquity = data['total_equity'] as double;

    // Draw report header
    page.graphics.drawString(
      title,
      PdfStandardFont(PdfFontFamily.helvetica, 24),
      bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, 50),
      format: PdfStringFormat(alignment: PdfTextAlignment.center)
    );

    // Draw organization and year
    page.graphics.drawString(
      'Organization: $organization',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(0, 60, page.getClientSize().width, 20)
    );

    page.graphics.drawString(
      'Year: $year',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(0, 80, page.getClientSize().width, 20)
    );

    // Draw balance sheet sections
    var yOffset = 120.0;
    
    // Assets Section
    page.graphics.drawString(
      'Assets',
      PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(0, yOffset, page.getClientSize().width, 20)
    );
    yOffset += 30;
    page.graphics.drawString(
      'Total Assets: \$${totalAssets.toStringAsFixed(2)}',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(20, yOffset, page.getClientSize().width - 40, 20)
    );

    // Liabilities Section
    yOffset += 40;
    page.graphics.drawString(
      'Liabilities',
      PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(0, yOffset, page.getClientSize().width, 20)
    );
    yOffset += 30;
    page.graphics.drawString(
      'Total Liabilities: \$${totalLiabilities.toStringAsFixed(2)}',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(20, yOffset, page.getClientSize().width - 40, 20)
    );

    // Equity Section
    yOffset += 40;
    page.graphics.drawString(
      'Equity',
      PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(0, yOffset, page.getClientSize().width, 20)
    );
    yOffset += 30;
    page.graphics.drawString(
      'Total Equity: \$${totalEquity.toStringAsFixed(2)}',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(20, yOffset, page.getClientSize().width - 40, 20)
    );

    // Draw total
    yOffset += 40;
    page.graphics.drawString(
      'Total Liabilities + Equity: \$${(totalLiabilities + totalEquity).toStringAsFixed(2)}',
      PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(0, yOffset, page.getClientSize().width, 20)
    );
  }
} 