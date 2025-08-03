import 'package:flutter/material.dart';
import '../components/organization_toggle.dart';
import '../components/audit_manual_entry.dart';

import '../reports/semi_annual_audit_service.dart';
import '../theme/app_theme.dart';

class SemiAnnualAuditEntryScreen extends StatefulWidget {
  const SemiAnnualAuditEntryScreen({super.key});

  @override
  State<SemiAnnualAuditEntryScreen> createState() => _SemiAnnualAuditEntryScreenState();
}

class _SemiAnnualAuditEntryScreenState extends State<SemiAnnualAuditEntryScreen> {
  String _selectedPeriod = 'December';
  int _selectedYear = DateTime.now().year;
  bool _isGenerating = false;
  final Map<String, String> _manualValues = {};

  void _handleManualValuesChanged(Map<String, String> values) {
    setState(() {
      _manualValues.clear();
      _manualValues.addAll(values);
    });
  }

  Future<void> _handleGenerateReport() async {
    setState(() => _isGenerating = true);
    try {
      await SemiAnnualAuditService().generateAuditReport(
        _selectedPeriod,
        _selectedYear,
        _manualValues,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report generated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: \\${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Report Data Entry')),
      body: AppTheme.screenContent(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const OrganizationToggle(),
              const SizedBox(height: AppTheme.spacing),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: AppTheme.formFieldDecorationWithLabel('Report Period Ends'),
                      value: _selectedPeriod,
                      items: const [
                        DropdownMenuItem(value: 'June', child: Text('June')),
                        DropdownMenuItem(value: 'December', child: Text('December')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedPeriod = value);
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: AppTheme.formFieldDecorationWithLabel('Report Year'),
                      value: _selectedYear,
                      items: List.generate(6, (index) => (DateTime.now().year + index))
                          .map((year) => DropdownMenuItem(
                                value: year,
                                child: Text(year.toString()),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedYear = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing),
              AuditManualEntry(
                initialValues: _manualValues,
                onValuesChanged: _handleManualValuesChanged,
              ),
              const SizedBox(height: AppTheme.spacing),
              FilledButton.icon(
                onPressed: _isGenerating ? null : _handleGenerateReport,
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
                    : const Icon(Icons.summarize),
                label: Text(_isGenerating ? 'Generating...' : 'Generate Audit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 