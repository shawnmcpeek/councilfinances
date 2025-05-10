import 'package:flutter/material.dart';
import '../components/period_report_selector.dart';
import '../reports/period_report_service.dart';

class PeriodReportScreen extends StatelessWidget {
  final PeriodReportService _reportService = PeriodReportService();

  PeriodReportScreen({Key? key}) : super(key: key);

  Future<void> _handleGenerateReport(String period, int year) async {
    try {
      final reportFile = await _reportService.generateReport(period, year);
      // TODO: Handle the generated report file
      // This could include:
      // 1. Opening the PDF
      // 2. Saving it to a specific location
      // 3. Sharing it
      // 4. etc.
    } catch (e) {
      // TODO: Handle errors appropriately
      print('Error generating report: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Audit Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PeriodReportSelector(
              onGenerateReport: _handleGenerateReport,
            ),
            const SizedBox(height: 24),
            // TODO: Add a preview or status section here
          ],
        ),
      ),
    );
  }
} 