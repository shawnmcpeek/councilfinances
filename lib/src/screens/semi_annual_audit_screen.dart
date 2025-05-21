import 'package:flutter/material.dart';
import '../components/semi_annual_audit_selector.dart';
import '../components/audit_manual_entry.dart';
import '../reports/semi_annual_audit_service.dart';
import '../theme/app_theme.dart';

class SemiAnnualAuditScreen extends StatefulWidget {
  const SemiAnnualAuditScreen({super.key});

  @override
  State<SemiAnnualAuditScreen> createState() => _SemiAnnualAuditScreenState();
}

class _SemiAnnualAuditScreenState extends State<SemiAnnualAuditScreen> {
  final SemiAnnualAuditService _reportService = SemiAnnualAuditService();
  bool _isGenerating = false;
  final Map<String, String> _manualValues = {};

  Future<void> _handleGenerateReport(String period, int year) async {
    setState(() => _isGenerating = true);
    try {
      await _reportService.generateAuditReport(period, year, _manualValues);
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
        setState(() => _isGenerating = false);
      }
    }
  }

  void _handleManualValuesChanged(Map<String, String> values) {
    setState(() => _manualValues.clear());
    _manualValues.addAll(values);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Semi-Annual Audit Report'),
      ),
      body: AppTheme.screenContent(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SemiAnnualAuditSelector(
                isGenerating: _isGenerating,
                onGenerate: _handleGenerateReport,
              ),
              const SizedBox(height: AppTheme.spacing),
              AuditManualEntry(
                initialValues: _manualValues,
                onValuesChanged: _handleManualValuesChanged,
              ),
              if (_isGenerating) ...[
                const SizedBox(height: AppTheme.spacing),
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: AppTheme.smallSpacing),
                      Text('Generating audit report...'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 