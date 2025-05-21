import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'form1728_report_service.dart';

class Form1728Report extends StatefulWidget {
  final String organizationId;
  final String selectedYear;
  final bool isGenerating;
  final Function(bool) onGeneratingChange;
  final Function(String) onYearChange;

  const Form1728Report({
    super.key,
    required this.organizationId,
    required this.selectedYear,
    required this.isGenerating,
    required this.onGeneratingChange,
    required this.onYearChange,
  });

  @override
  State<Form1728Report> createState() => _Form1728ReportState();
}

class _Form1728ReportState extends State<Form1728Report> {
  Future<void> _generateReport() async {
    widget.onGeneratingChange(true);
    try {
      final reportService = Form1728ReportService();
      await reportService.generateForm1728Report(widget.organizationId, widget.selectedYear);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report generated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        widget.onGeneratingChange(false);
      }
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
              'Form 1728 Program Report',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            Text(
              'Generate annual program activity report',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppTheme.spacing),
            DropdownButtonFormField<String>(
              decoration: AppTheme.formFieldDecoration.copyWith(
                labelText: 'Report Year',
              ),
              value: widget.selectedYear,
              items: const [
                DropdownMenuItem(value: '2024', child: Text('2024')),
                DropdownMenuItem(value: '2025', child: Text('2025')),
                DropdownMenuItem(value: '2026', child: Text('2026')),
                DropdownMenuItem(value: '2027', child: Text('2027')),
                DropdownMenuItem(value: '2028', child: Text('2028')),
                DropdownMenuItem(value: '2029', child: Text('2029')),
              ],
              onChanged: (value) {
                if (value != null) {
                  widget.onYearChange(value);
                }
              },
            ),
            const SizedBox(height: AppTheme.spacing),
            FilledButton.icon(
              onPressed: widget.isGenerating ? null : _generateReport,
              style: AppTheme.filledButtonStyle,
              icon: widget.isGenerating 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.summarize),
              label: Text(widget.isGenerating ? 'Generating...' : 'Generate Report'),
            ),
          ],
        ),
      ),
    );
  }
} 