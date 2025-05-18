import 'package:flutter/material.dart';
import '../components/period_report_selector.dart';
import '../reports/period_report_service.dart';
import '../theme/app_theme.dart';
import '../utils/logger.dart';

class PeriodReportScreen extends StatefulWidget {
  const PeriodReportScreen({super.key});

  @override
  State<PeriodReportScreen> createState() => _PeriodReportScreenState();
}

class _PeriodReportScreenState extends State<PeriodReportScreen> {
  final PeriodReportService _reportService = PeriodReportService();
  bool _isGenerating = false;

  Future<void> _handleGenerateReport(String period, int year) async {
    if (_isGenerating) return;

    setState(() => _isGenerating = true);
    try {
      await _reportService.generateReport(period, year);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report generated successfully')),
        );
      }
    } catch (e) {
      AppLogger.error('Error generating report', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Audit Report'),
      ),
      body: AppTheme.screenContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PeriodReportSelector(
              isGenerating: _isGenerating,
              onGenerate: _handleGenerateReport,
            ),
            if (_isGenerating) ...[
              const SizedBox(height: 24),
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Generating report...'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 