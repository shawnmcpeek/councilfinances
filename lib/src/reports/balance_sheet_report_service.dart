import 'dart:ui';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../services/balance_sheet_service.dart';
import '../services/report_file_saver.dart';
import '../utils/logger.dart';
import '../utils/formatters.dart' as formatters;
import 'base_pdf_report_service.dart';

class BalanceSheetReportService extends BasePdfReportService {
  final BalanceSheetService _balanceSheetService = BalanceSheetService();

  @override
  String get templatePath => ''; // No template file, we generate from scratch

  Future<void> _generateLandscapePdf(Map<String, dynamic> data, String fileName, String reportTitle) async {
    try {
      AppLogger.info('Generating landscape PDF report: $fileName');

      // 1. Create a new PDF document
      final document = PdfDocument();
      document.pageSettings.size = PdfPageSize.a4;
      document.pageSettings.orientation = PdfPageOrientation.landscape;
      
      // 2. Draw the report content with pagination support
      await drawReportContentWithPagination(document, data);
      AppLogger.debug('Drew report content');

      // 3. Generate the PDF bytes
      final List<int> pdfBytes = await document.save();
      document.dispose();
      AppLogger.debug('Generated PDF bytes');

      // 4. Save or share the PDF
      await saveOrShareFile(pdfBytes, fileName, reportTitle);
      AppLogger.info('Report saved/shared successfully: $fileName');
    } catch (e, stackTrace) {
      AppLogger.error('Error generating landscape PDF report', e, stackTrace);
      rethrow;
    }
  }





  Future<void> generateBalanceSheetReport(String organizationId, String year) async {
    try {
      AppLogger.info('Generating balance sheet report for organization $organizationId for year $year');
      
      // Get balance sheet data
      final balanceSheetData = await _balanceSheetService.getBalanceSheetData(organizationId, year);
      AppLogger.debug('Retrieved balance sheet data');

      // Prepare data for PDF generation
      final data = {
        'title': 'Balance Sheet Report',
        'organization': organizationId,
        'year': year,
        'balance_sheet_data': balanceSheetData,
      };

      // Generate landscape PDF
      final fileName = 'balance_sheet_${organizationId}_$year.pdf';
      await _generateLandscapePdf(data, fileName, 'Balance Sheet Report for $year');

      AppLogger.info('Balance sheet report generated and saved/shared successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error generating balance sheet report', e, stackTrace);
      rethrow;
    }
  }

  Future<void> drawReportContentWithPagination(PdfDocument document, Map<String, dynamic> data) async {
    final title = data['title'] as String;
    final organization = data['organization'] as String;
    final year = data['year'] as String;
    final balanceSheetData = data['balance_sheet_data'] as BalanceSheetData;

    // Set up fonts with larger sizes for better readability
    final PdfFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 20, style: PdfFontStyle.bold);
    final PdfFont headerFont = PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold);
    final PdfFont bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 12);
    final PdfFont sectionFont = PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold);

    final margin = 25.0;
    final formattedOrgName = _formatOrganizationName(organization);

    // Page 1: Income (Jan-Jun)
    PdfPage incomePage1 = document.pages.add();
    final pageSize = incomePage1.getClientSize();
    final contentWidth = pageSize.width - (2 * margin);
    double yPosition = margin;

    // Draw header on first page
    incomePage1.graphics.drawString(
      title,
      titleFont,
      bounds: Rect.fromLTWH(margin, yPosition, contentWidth, 35),
      format: PdfStringFormat(alignment: PdfTextAlignment.center)
    );
    yPosition += 45;

    incomePage1.graphics.drawString(
      'Organization: $formattedOrgName',
      bodyFont,
      bounds: Rect.fromLTWH(margin, yPosition, contentWidth / 2, 25)
    );
    incomePage1.graphics.drawString(
      'Year: $year',
      bodyFont,
      bounds: Rect.fromLTWH(margin + contentWidth / 2, yPosition, contentWidth / 2, 25),
      format: PdfStringFormat(alignment: PdfTextAlignment.right)
    );
    yPosition += 35;

    // Draw Income Section header
    incomePage1.graphics.drawString(
      'INCOME (January - June)',
      sectionFont,
      bounds: Rect.fromLTWH(margin, yPosition, contentWidth, 25),
      format: PdfStringFormat(alignment: PdfTextAlignment.center)
    );
    yPosition += 30;

    // Create Income grid for Jan-Jun
    final incomeGrid1 = _createBalanceSheetGrid(
      balanceSheetData.incomeRows, 
      balanceSheetData.monthlyIncomeTotals, 
      false, 
      180.0, // Wider program name column
      85.0,  // Wider month columns
      100.0, // Wider total column
      [1, 2, 3, 4, 5, 6] // Only Jan-Jun months
    );
    
    incomeGrid1.draw(
      page: incomePage1,
      bounds: Rect.fromLTWH(margin, yPosition, contentWidth, pageSize.height - yPosition - margin),
      format: PdfLayoutFormat(
        breakType: PdfLayoutBreakType.fitPage,
        layoutType: PdfLayoutType.paginate
      )
    );

    // Page 2: Income (Jul-Dec)
    PdfPage incomePage2 = document.pages.add();
    yPosition = margin;

    // Draw header on second page
    incomePage2.graphics.drawString(
      title,
      titleFont,
      bounds: Rect.fromLTWH(margin, yPosition, contentWidth, 35),
      format: PdfStringFormat(alignment: PdfTextAlignment.center)
    );
    yPosition += 45;

    incomePage2.graphics.drawString(
      'Organization: $formattedOrgName',
      bodyFont,
      bounds: Rect.fromLTWH(margin, yPosition, contentWidth / 2, 25)
    );
    incomePage2.graphics.drawString(
      'Year: $year',
      bodyFont,
      bounds: Rect.fromLTWH(margin + contentWidth / 2, yPosition, contentWidth / 2, 25),
      format: PdfStringFormat(alignment: PdfTextAlignment.right)
    );
    yPosition += 35;

    // Draw Income Section header
    incomePage2.graphics.drawString(
      'INCOME (July - December)',
      sectionFont,
      bounds: Rect.fromLTWH(margin, yPosition, contentWidth, 25),
      format: PdfStringFormat(alignment: PdfTextAlignment.center)
    );
    yPosition += 30;

    // Create Income grid for Jul-Dec
    final incomeGrid2 = _createBalanceSheetGrid(
      balanceSheetData.incomeRows, 
      balanceSheetData.monthlyIncomeTotals, 
      false, 
      180.0, // Wider program name column
      85.0,  // Wider month columns
      100.0, // Wider total column
      [7, 8, 9, 10, 11, 12] // Only Jul-Dec months
    );
    
    incomeGrid2.draw(
      page: incomePage2,
      bounds: Rect.fromLTWH(margin, yPosition, contentWidth, pageSize.height - yPosition - margin),
      format: PdfLayoutFormat(
        breakType: PdfLayoutBreakType.fitPage,
        layoutType: PdfLayoutType.paginate
      )
    );

    // Page 3: Expenses (Jan-Jun)
    PdfPage expensePage1 = document.pages.add();
    yPosition = margin;

    // Draw header on third page
    expensePage1.graphics.drawString(
      title,
      titleFont,
      bounds: Rect.fromLTWH(margin, yPosition, contentWidth, 35),
      format: PdfStringFormat(alignment: PdfTextAlignment.center)
    );
    yPosition += 45;

    expensePage1.graphics.drawString(
      'Organization: $formattedOrgName',
      bodyFont,
      bounds: Rect.fromLTWH(margin, yPosition, contentWidth / 2, 25)
    );
    expensePage1.graphics.drawString(
      'Year: $year',
      bodyFont,
      bounds: Rect.fromLTWH(margin + contentWidth / 2, yPosition, contentWidth / 2, 25),
      format: PdfStringFormat(alignment: PdfTextAlignment.right)
    );
    yPosition += 35;

    // Draw Expense Section header
    expensePage1.graphics.drawString(
      'EXPENSES (January - June)',
      sectionFont,
      bounds: Rect.fromLTWH(margin, yPosition, contentWidth, 25),
      format: PdfStringFormat(alignment: PdfTextAlignment.center)
    );
    yPosition += 30;

    // Create Expense grid for Jan-Jun
    final expenseGrid1 = _createBalanceSheetGrid(
      balanceSheetData.expenseRows, 
      balanceSheetData.monthlyExpenseTotals, 
      true, 
      180.0, // Wider program name column
      85.0,  // Wider month columns
      100.0, // Wider total column
      [1, 2, 3, 4, 5, 6] // Only Jan-Jun months
    );
    
    expenseGrid1.draw(
      page: expensePage1,
      bounds: Rect.fromLTWH(margin, yPosition, contentWidth, pageSize.height - yPosition - margin),
      format: PdfLayoutFormat(
        breakType: PdfLayoutBreakType.fitPage,
        layoutType: PdfLayoutType.paginate
      )
    );

    // Page 4: Expenses (Jul-Dec)
    PdfPage expensePage2 = document.pages.add();
    yPosition = margin;

    // Draw header on fourth page
    expensePage2.graphics.drawString(
      title,
      titleFont,
      bounds: Rect.fromLTWH(margin, yPosition, contentWidth, 35),
      format: PdfStringFormat(alignment: PdfTextAlignment.center)
    );
    yPosition += 45;

    expensePage2.graphics.drawString(
      'Organization: $formattedOrgName',
      bodyFont,
      bounds: Rect.fromLTWH(margin, yPosition, contentWidth / 2, 25)
    );
    expensePage2.graphics.drawString(
      'Year: $year',
      bodyFont,
      bounds: Rect.fromLTWH(margin + contentWidth / 2, yPosition, contentWidth / 2, 25),
      format: PdfStringFormat(alignment: PdfTextAlignment.right)
    );
    yPosition += 35;

    // Draw Expense Section header
    expensePage2.graphics.drawString(
      'EXPENSES (July - December)',
      sectionFont,
      bounds: Rect.fromLTWH(margin, yPosition, contentWidth, 25),
      format: PdfStringFormat(alignment: PdfTextAlignment.center)
    );
    yPosition += 30;

    // Create Expense grid for Jul-Dec
    final expenseGrid2 = _createBalanceSheetGrid(
      balanceSheetData.expenseRows, 
      balanceSheetData.monthlyExpenseTotals, 
      true, 
      180.0, // Wider program name column
      85.0,  // Wider month columns
      100.0, // Wider total column
      [7, 8, 9, 10, 11, 12] // Only Jul-Dec months
    );
    
    expenseGrid2.draw(
      page: expensePage2,
      bounds: Rect.fromLTWH(margin, yPosition, contentWidth, pageSize.height - yPosition - margin),
      format: PdfLayoutFormat(
        breakType: PdfLayoutBreakType.fitPage,
        layoutType: PdfLayoutType.paginate
      )
    );
  }

  String _formatOrganizationName(String organizationId) {
    if (organizationId.isEmpty) return organizationId;
    
    final firstChar = organizationId[0].toUpperCase();
    final numberPart = organizationId.substring(1);
    
    // Remove leading zeros
    final cleanNumber = numberPart.replaceAll(RegExp(r'^0+'), '');
    
    switch (firstChar) {
      case 'C':
        return 'Council $cleanNumber';
      case 'A':
        return 'Assembly $cleanNumber';
      default:
        return organizationId; // Return as-is if not C or A
    }
  }

  PdfGrid _createBalanceSheetGrid(List<BalanceSheetRow> rows, Map<int, double> monthlyTotals, bool isExpense, double programNameWidth, double monthWidth, double totalWidth, List<int> months) {
    // Create a PdfGrid
    PdfGrid grid = PdfGrid();
    
    // Add columns to grid (Program Name + specified months + Total)
    final columnCount = 1 + months.length + 1; // Program Name + months + Total
    grid.columns.add(count: columnCount);
    
    // Set column widths using the passed variables
    grid.columns[0].width = programNameWidth; // Program Name
    for (int i = 0; i < months.length; i++) {
      grid.columns[i + 1].width = monthWidth; // Month columns
    }
    grid.columns[columnCount - 1].width = totalWidth; // Total column
    
    // Add header row
    grid.headers.add(1);
    PdfGridRow header = grid.headers[0];
    header.cells[0].value = 'Program Name';
    
    // Add month headers
    for (int i = 0; i < months.length; i++) {
      final month = months[i];
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      header.cells[i + 1].value = monthNames[month - 1];
    }
    header.cells[columnCount - 1].value = 'Total';
    
    // Add data rows
    for (final row in rows) {
      PdfGridRow gridRow = grid.rows.add();
      gridRow.cells[0].value = row.programName;
      
      // Add monthly amounts for specified months
      for (int i = 0; i < months.length; i++) {
        final month = months[i];
        gridRow.cells[i + 1].value = formatters.formatCurrency(row.monthlyAmounts[month] ?? 0.0);
      }
      
      // Calculate total for specified months
      double periodTotal = 0.0;
      for (final month in months) {
        periodTotal += row.monthlyAmounts[month] ?? 0.0;
      }
      gridRow.cells[columnCount - 1].value = formatters.formatCurrency(periodTotal);
    }
    
    // Add totals row
    PdfGridRow totalsRow = grid.rows.add();
    totalsRow.cells[0].value = 'Monthly Totals';
    
    // Add monthly totals for specified months
    for (int i = 0; i < months.length; i++) {
      final month = months[i];
      totalsRow.cells[i + 1].value = formatters.formatCurrency(monthlyTotals[month] ?? 0.0);
    }
    
    // Calculate total for specified months
    double periodTotal = 0.0;
    for (final month in months) {
      periodTotal += monthlyTotals[month] ?? 0.0;
    }
    totalsRow.cells[columnCount - 1].value = formatters.formatCurrency(periodTotal);
    
    // Style the grid with larger fonts for better readability
    grid.style = PdfGridStyle(
      cellPadding: PdfPaddings(left: 3, right: 3, top: 4, bottom: 4), // More padding
      font: PdfStandardFont(PdfFontFamily.helvetica, 10), // Larger font (was 6)
    );
    
    // Style the header
    header.style = PdfGridRowStyle(
      backgroundBrush: PdfBrushes.lightGray,
      font: PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold), // Larger font (was 6)
    );
    
    // Style the totals row
    totalsRow.style = PdfGridRowStyle(
      backgroundBrush: PdfBrushes.lightYellow,
      font: PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold), // Larger font (was 6)
    );
    
    return grid;
  }

  @override
  Future<void> drawReportContent(PdfPage page, Map<String, dynamic> data) async {
    final title = data['title'] as String;
    final organization = data['organization'] as String;
    final year = data['year'] as String;
    final balanceSheetData = data['balance_sheet_data'] as BalanceSheetData;

    final pageSize = page.getClientSize();
    final margin = 20.0; // Smaller margin for landscape
    final contentWidth = pageSize.width - (2 * margin);
    double yPosition = margin;

    // Set up fonts
    final PdfFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
    final PdfFont headerFont = PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold);
    final PdfFont sectionFont = PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold);
    final PdfFont bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
    final PdfFont smallFont = PdfStandardFont(PdfFontFamily.helvetica, 8);

    // Draw title
    page.graphics.drawString(
      title,
      titleFont,
      bounds: Rect.fromLTWH(margin, yPosition, contentWidth, 30),
      format: PdfStringFormat(alignment: PdfTextAlignment.center)
    );
    yPosition += 40;

    // Draw organization and year
    page.graphics.drawString(
      'Organization: $organization',
      bodyFont,
      bounds: Rect.fromLTWH(margin, yPosition, contentWidth / 2, 20)
    );
    page.graphics.drawString(
      'Year: $year',
      bodyFont,
      bounds: Rect.fromLTWH(margin + contentWidth / 2, yPosition, contentWidth / 2, 20),
      format: PdfStringFormat(alignment: PdfTextAlignment.right)
    );
    yPosition += 30;

    // Define column widths for the table - wider for landscape
    final programNameWidth = 150.0;
    final monthWidth = 70.0;
    final totalWidth = 90.0;
    final tableWidth = programNameWidth + (12 * monthWidth) + totalWidth;

    // Draw Income Section
    yPosition = _drawSectionHeader(page, 'INCOME', margin, yPosition, tableWidth, headerFont);
    yPosition = _drawDataTable(
      page, 
      balanceSheetData.incomeRows, 
      balanceSheetData.monthlyIncomeTotals, 
      margin, 
      yPosition, 
      programNameWidth, 
      monthWidth, 
      totalWidth, 
      bodyFont, 
      smallFont,
      false
    );

    yPosition += 20;

    // Draw Expense Section
    yPosition = _drawSectionHeader(page, 'EXPENSES', margin, yPosition, tableWidth, headerFont);
    yPosition = _drawDataTable(
      page, 
      balanceSheetData.expenseRows, 
      balanceSheetData.monthlyExpenseTotals, 
      margin, 
      yPosition, 
      programNameWidth, 
      monthWidth, 
      totalWidth, 
      bodyFont, 
      smallFont,
      true
    );

    yPosition += 20;

    // Draw Net Position Row
    _drawNetPositionRow(
      page,
      balanceSheetData,
      margin,
      yPosition,
      programNameWidth,
      monthWidth,
      totalWidth,
      sectionFont,
    );
  }

  double _drawSectionHeader(PdfPage page, String title, double margin, double yPosition, double tableWidth, PdfFont font) {
    // Draw section background
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(240, 240, 240)),
      bounds: Rect.fromLTWH(margin, yPosition, tableWidth, 25)
    );

    // Draw section title
    page.graphics.drawString(
      title,
      font,
      brush: PdfSolidBrush(PdfColor(0, 0, 0)),
      bounds: Rect.fromLTWH(margin + 10, yPosition + 5, tableWidth - 20, 20)
    );

    return yPosition + 30;
  }

  double _drawDataTable(
    PdfPage page,
    List<BalanceSheetRow> rows,
    Map<int, double> monthlyTotals,
    double margin,
    double yPosition,
    double programNameWidth,
    double monthWidth,
    double totalWidth,
    PdfFont bodyFont,
    PdfFont smallFont,
    bool isExpense,
  ) {
    return _drawDataTableWithPagination(
      page,
      rows,
      monthlyTotals,
      margin,
      yPosition,
      programNameWidth,
      monthWidth,
      totalWidth,
      bodyFont,
      smallFont,
      isExpense,
      null, // No document reference for single page
      null, // No current page reference for single page
    );
  }

  double _drawDataTableWithPagination(
    PdfPage page,
    List<BalanceSheetRow> rows,
    Map<int, double> monthlyTotals,
    double margin,
    double yPosition,
    double programNameWidth,
    double monthWidth,
    double totalWidth,
    PdfFont bodyFont,
    PdfFont smallFont,
    bool isExpense,
    PdfDocument? document,
    PdfPage? currentPage,
  ) {
    final rowHeight = 20.0;
    final pageSize = page.getClientSize();
    final maxPageHeight = pageSize.height - (2 * margin);
    PdfPage workingPage = page;
    double workingYPosition = yPosition;

    // Check if we need a new page for the header
    if (workingYPosition + rowHeight > maxPageHeight && document != null && currentPage != null) {
      workingPage = document.pages.add();
      workingYPosition = margin;
    }

    // Draw table header
    _drawTableRow(
      workingPage,
      margin,
      workingYPosition,
      programNameWidth,
      monthWidth,
      totalWidth,
      rowHeight,
      ['Program Name', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Total'],
      smallFont,
      PdfColor(220, 220, 220),
      true
    );
    workingYPosition += rowHeight;

    // Draw data rows
    for (final row in rows) {
      final rowData = [
        row.programName,
        formatters.formatCurrency(row.monthlyAmounts[1] ?? 0.0),
        formatters.formatCurrency(row.monthlyAmounts[2] ?? 0.0),
        formatters.formatCurrency(row.monthlyAmounts[3] ?? 0.0),
        formatters.formatCurrency(row.monthlyAmounts[4] ?? 0.0),
        formatters.formatCurrency(row.monthlyAmounts[5] ?? 0.0),
        formatters.formatCurrency(row.monthlyAmounts[6] ?? 0.0),
        formatters.formatCurrency(row.monthlyAmounts[7] ?? 0.0),
        formatters.formatCurrency(row.monthlyAmounts[8] ?? 0.0),
        formatters.formatCurrency(row.monthlyAmounts[9] ?? 0.0),
        formatters.formatCurrency(row.monthlyAmounts[10] ?? 0.0),
        formatters.formatCurrency(row.monthlyAmounts[11] ?? 0.0),
        formatters.formatCurrency(row.monthlyAmounts[12] ?? 0.0),
        formatters.formatCurrency(row.yearlyTotal),
      ];

      _drawTableRow(
        page,
        margin,
        yPosition,
        programNameWidth,
        monthWidth,
        totalWidth,
        rowHeight,
        rowData,
        smallFont,
        PdfColor(255, 255, 255),
        false
      );
      yPosition += rowHeight;
    }

    // Draw totals row
    final totalsData = [
      'Monthly Totals',
      formatters.formatCurrency(monthlyTotals[1] ?? 0.0),
      formatters.formatCurrency(monthlyTotals[2] ?? 0.0),
      formatters.formatCurrency(monthlyTotals[3] ?? 0.0),
      formatters.formatCurrency(monthlyTotals[4] ?? 0.0),
      formatters.formatCurrency(monthlyTotals[5] ?? 0.0),
      formatters.formatCurrency(monthlyTotals[6] ?? 0.0),
      formatters.formatCurrency(monthlyTotals[7] ?? 0.0),
      formatters.formatCurrency(monthlyTotals[8] ?? 0.0),
      formatters.formatCurrency(monthlyTotals[9] ?? 0.0),
      formatters.formatCurrency(monthlyTotals[10] ?? 0.0),
      formatters.formatCurrency(monthlyTotals[11] ?? 0.0),
      formatters.formatCurrency(monthlyTotals[12] ?? 0.0),
      formatters.formatCurrency(monthlyTotals.values.fold(0.0, (sum, amount) => sum + amount)),
    ];

    _drawTableRow(
      page,
      margin,
      yPosition,
      programNameWidth,
      monthWidth,
      totalWidth,
      rowHeight,
      totalsData,
      bodyFont,
      PdfColor(245, 245, 245),
      true
    );
    yPosition += rowHeight;

    return yPosition;
  }

  void _drawTableRow(
    PdfPage page,
    double margin,
    double yPosition,
    double programNameWidth,
    double monthWidth,
    double totalWidth,
    double rowHeight,
    List<String> data,
    PdfFont font,
    PdfColor backgroundColor,
    bool isBold,
  ) {
    // Draw row background
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(backgroundColor),
      bounds: Rect.fromLTWH(margin, yPosition, programNameWidth + (12 * monthWidth) + totalWidth, rowHeight)
    );

    // Draw borders
    page.graphics.drawRectangle(
      pen: PdfPen(PdfColor(200, 200, 200)),
      bounds: Rect.fromLTWH(margin, yPosition, programNameWidth + (12 * monthWidth) + totalWidth, rowHeight)
    );

    // Draw program name column
    page.graphics.drawString(
      data[0],
      font,
      brush: PdfSolidBrush(PdfColor(0, 0, 0)),
      bounds: Rect.fromLTWH(margin + 5, yPosition + 5, programNameWidth - 10, rowHeight - 10)
    );

    // Draw month columns
    for (int i = 0; i < 12; i++) {
      final x = margin + programNameWidth + (i * monthWidth);
      page.graphics.drawString(
        data[i + 1],
        font,
        brush: PdfSolidBrush(PdfColor(0, 0, 0)),
        bounds: Rect.fromLTWH(x + 2, yPosition + 5, monthWidth - 4, rowHeight - 10),
        format: PdfStringFormat(alignment: PdfTextAlignment.right)
      );
    }

    // Draw total column
    final totalX = margin + programNameWidth + (12 * monthWidth);
    page.graphics.drawString(
      data[13],
      font,
      brush: PdfSolidBrush(PdfColor(0, 0, 0)),
      bounds: Rect.fromLTWH(totalX + 2, yPosition + 5, totalWidth - 4, rowHeight - 10),
      format: PdfStringFormat(alignment: PdfTextAlignment.right)
    );
  }

  void _drawNetPositionRow(
    PdfPage page,
    BalanceSheetData balanceSheetData,
    double margin,
    double yPosition,
    double programNameWidth,
    double monthWidth,
    double totalWidth,
    PdfFont font,
  ) {
    final tableWidth = programNameWidth + (12 * monthWidth) + totalWidth;
    final rowHeight = 25.0;

    // Draw net position background
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(240, 248, 255)), // Light blue background
      bounds: Rect.fromLTWH(margin, yPosition, tableWidth, rowHeight)
    );

    // Draw borders
    page.graphics.drawRectangle(
      pen: PdfPen(PdfColor(100, 149, 237)), // Cornflower blue border
      bounds: Rect.fromLTWH(margin, yPosition, tableWidth, rowHeight)
    );

    // Draw "NET POSITION" label
    page.graphics.drawString(
      'NET POSITION',
      font,
      brush: PdfSolidBrush(PdfColor(0, 0, 139)), // Dark blue text
      bounds: Rect.fromLTWH(margin + 5, yPosition + 5, programNameWidth - 10, rowHeight - 10)
    );

    // Draw monthly net amounts
    for (int month = 1; month <= 12; month++) {
      final netAmount = (balanceSheetData.monthlyIncomeTotals[month] ?? 0.0) -
                       (balanceSheetData.monthlyExpenseTotals[month] ?? 0.0);
      final x = margin + programNameWidth + ((month - 1) * monthWidth);
      
      page.graphics.drawString(
        formatters.formatCurrency(netAmount),
        font,
        brush: PdfSolidBrush(netAmount >= 0 ? PdfColor(0, 128, 0) : PdfColor(220, 20, 60)), // Green for positive, red for negative
        bounds: Rect.fromLTWH(x + 2, yPosition + 5, monthWidth - 4, rowHeight - 10),
        format: PdfStringFormat(alignment: PdfTextAlignment.right)
      );
    }

    // Draw yearly net total
    final totalX = margin + programNameWidth + (12 * monthWidth);
    final yearlyNet = balanceSheetData.yearlyNetTotal;
    page.graphics.drawString(
      formatters.formatCurrency(yearlyNet),
      font,
      brush: PdfSolidBrush(yearlyNet >= 0 ? PdfColor(0, 128, 0) : PdfColor(220, 20, 60)), // Green for positive, red for negative
      bounds: Rect.fromLTWH(totalX + 2, yPosition + 5, totalWidth - 4, rowHeight - 10),
      format: PdfStringFormat(alignment: PdfTextAlignment.right)
    );
  }
} 