import 'package:flutter/material.dart';
import '../services/balance_sheet_service.dart';
import '../reports/balance_sheet_report_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart' as formatters;

class BalanceSheetWidget extends StatefulWidget {
  final String organizationId;

  const BalanceSheetWidget({
    super.key,
    required this.organizationId,
  });

  @override
  State<BalanceSheetWidget> createState() => _BalanceSheetWidgetState();
}

class _BalanceSheetWidgetState extends State<BalanceSheetWidget> {
  final BalanceSheetService _balanceSheetService = BalanceSheetService();
  BalanceSheetData? _balanceSheetData;
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;
  String _selectedYear = DateTime.now().year.toString();

  @override
  void initState() {
    super.initState();
    _loadBalanceSheetData();
  }

  @override
  void didUpdateWidget(BalanceSheetWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organizationId != widget.organizationId) {
      _loadBalanceSheetData();
    }
  }

  Future<void> _loadBalanceSheetData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _balanceSheetService.getBalanceSheetData(
        widget.organizationId,
        _selectedYear,
      );
      
      setState(() {
        _balanceSheetData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppTheme.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance Sheet - $_selectedYear',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            Text(
              'Financial summary by program and month',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppTheme.spacing),
            
            // Year selector and generate button
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Report Year',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      (DateTime.now().year - 1).toString(),
                      DateTime.now().year.toString(),
                      (DateTime.now().year + 1).toString(),
                    ].map((year) {
                      return DropdownMenuItem<String>(
                        value: year,
                        child: Text(year),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedYear = value;
                        });
                        _loadBalanceSheetData();
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppTheme.spacing),
                FilledButton.icon(
                  onPressed: _isGenerating ? null : _generatePDF,
                  style: AppTheme.filledButtonStyle,
                  icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf),
                  label: Text(_isGenerating ? 'Generating...' : 'Generate PDF'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              _buildErrorWidget()
            else if (_balanceSheetData != null)
              _buildBalanceSheetTable()
            else
              const Center(child: Text('No data available')),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: AppTheme.cardPadding,
        child: Column(
          children: [
            Icon(Icons.error, color: Colors.red[700], size: 48),
            const SizedBox(height: AppTheme.smallSpacing),
            Text(
              'Error loading balance sheet data',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing),
            FilledButton.icon(
              onPressed: _loadBalanceSheetData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSheetTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 1400), // Minimum width for the table
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Income Section
            _buildSectionHeader('INCOME'),
            const SizedBox(height: AppTheme.smallSpacing),
            _buildDataTable(_balanceSheetData!.incomeRows, _balanceSheetData!.monthlyIncomeTotals, false),
            
            const SizedBox(height: AppTheme.spacing),
            
            // Expense Section
            _buildSectionHeader('EXPENSES'),
            const SizedBox(height: AppTheme.smallSpacing),
            _buildDataTable(_balanceSheetData!.expenseRows, _balanceSheetData!.monthlyExpenseTotals, true),
            
            const SizedBox(height: AppTheme.spacing),
            
            // Net Position Row
            _buildNetPositionRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: 1400, // Fixed width to match table
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDataTable(List<BalanceSheetRow> rows, Map<int, double> monthlyTotals, bool isExpense) {
    return Table(
      border: TableBorder.all(color: Colors.grey[300]!),
      columnWidths: _getColumnWidths(),
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[100]),
          children: [
            _buildHeaderCell('Program Name'),
            ...List.generate(12, (index) => _buildHeaderCell(_getMonthName(index + 1))),
            _buildHeaderCell('Total'),
          ],
        ),
        // Data rows
        ...rows.map((row) => _buildDataRow(row)),
        // Totals row
        _buildTotalsRow(monthlyTotals, isExpense),
      ],
    );
  }

  Widget _buildNetPositionRow() {
    return Container(
      width: 1400, // Fixed width to match table
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[200]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Table(
        border: TableBorder.all(color: Colors.blue[200]!),
        columnWidths: _getColumnWidths(),
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.blue[100]),
            children: [
              _buildHeaderCell('NET POSITION', textColor: Colors.blue[800]),
              ...List.generate(12, (index) {
                final month = index + 1;
                final netAmount = (_balanceSheetData!.monthlyIncomeTotals[month] ?? 0.0) -
                                (_balanceSheetData!.monthlyExpenseTotals[month] ?? 0.0);
                return _buildDataCell(
                  formatters.formatCurrency(netAmount),
                  textColor: netAmount >= 0 ? Colors.green[700] : Colors.red[700],
                  fontWeight: FontWeight.bold,
                );
              }),
              _buildDataCell(
                formatters.formatCurrency(_balanceSheetData!.yearlyNetTotal),
                textColor: _balanceSheetData!.yearlyNetTotal >= 0 ? Colors.green[700] : Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<int, TableColumnWidth> _getColumnWidths() {
    return {
      0: const FixedColumnWidth(200), // Program name
      ...Map.fromEntries(
        List.generate(12, (index) => MapEntry(index + 1, const FixedColumnWidth(100)))
      ),
      13: const FixedColumnWidth(120), // Total column
    };
  }

  Widget _buildHeaderCell(String text, {Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(String text, {Color? textColor, FontWeight? fontWeight}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: fontWeight,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  TableRow _buildDataRow(BalanceSheetRow row) {
    return TableRow(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Text(
            row.programName,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        ...List.generate(12, (index) {
          final month = index + 1;
          final amount = row.monthlyAmounts[month] ?? 0.0;
          return _buildDataCell(formatters.formatCurrency(amount));
        }),
        _buildDataCell(
          formatters.formatCurrency(row.yearlyTotal),
          fontWeight: FontWeight.bold,
        ),
      ],
    );
  }

  TableRow _buildTotalsRow(Map<int, double> monthlyTotals, bool isExpense) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey[50]),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Text(
            'Monthly Totals',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...List.generate(12, (index) {
          final month = index + 1;
          final amount = monthlyTotals[month] ?? 0.0;
          return _buildDataCell(
            formatters.formatCurrency(amount),
            fontWeight: FontWeight.bold,
          );
        }),
        _buildDataCell(
          formatters.formatCurrency(
            isExpense ? _balanceSheetData!.yearlyExpenseTotal : _balanceSheetData!.yearlyIncomeTotal
          ),
          fontWeight: FontWeight.bold,
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return monthNames[month - 1];
  }

  Future<void> _generatePDF() async {
    if (_balanceSheetData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data available to generate PDF')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final pdfService = BalanceSheetReportService();
      await pdfService.generateBalanceSheetReport(
        widget.organizationId,
        _selectedYear,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Balance sheet PDF generated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }
} 