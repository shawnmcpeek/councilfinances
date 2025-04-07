import 'package:flutter/material.dart';
import '../services/report_service.dart';
import '../services/user_service.dart';
import '../utils/logger.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _reportService = ReportService();
  final _userService = UserService();
  String _selectedYear = '2024';
  bool _isGenerating = false;

  final List<String> _availableYears = [
    '2024', '2025', '2026', '2027', '2028', '2029'
  ];

  Future<void> _generateForm1728Report() async {
    setState(() => _isGenerating = true);
    try {
      final userProfile = await _userService.getUserProfile();
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      final organizationId = userProfile.assemblyNumber != null 
          ? 'A${userProfile.assemblyNumber.toString().padLeft(6, '0')}'
          : 'C${userProfile.councilNumber.toString().padLeft(6, '0')}';

      await _reportService.generateForm1728Report(organizationId, _selectedYear);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report generated successfully')),
        );
      }
    } catch (e) {
      AppLogger.error('Error generating report', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
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
        title: const Text('Reports'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Form 1728 Program Report',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Generate annual program activity report',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Report Year',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    value: _selectedYear,
                    items: _availableYears.map((year) {
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedYear = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generateForm1728Report,
                      icon: _isGenerating 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf),
                      label: Text(_isGenerating ? 'Generating...' : 'Generate Report'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // More report types can be added here
        ],
      ),
    );
  }
} 