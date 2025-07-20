import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'volunteer_hours_report_service.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';

class VolunteerHoursReport extends StatelessWidget {
  final String userId;
  final String organizationId;
  final String selectedYear;
  final bool isGenerating;
  final ValueChanged<bool> onGeneratingChange;
  final ValueChanged<String> onYearChange;

  const VolunteerHoursReport({
    super.key,
    required this.userId,
    required this.organizationId,
    required this.selectedYear,
    required this.isGenerating,
    required this.onGeneratingChange,
    required this.onYearChange,
  });

  Future<void> _generateReport(BuildContext context) async {
    if (isGenerating) return;
    
    onGeneratingChange(true);
    try {
      final service = VolunteerHoursReportService(
        context.read<UserService>(),
        Supabase.instance.client,
      );
      await service.generateVolunteerHoursReport(userId, selectedYear, organizationId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report generated successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: ${e.toString()}')),
        );
      }
    } finally {
      onGeneratingChange(false);
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
              'Volunteer Hours Report',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            Text(
              'Generate annual volunteer hours summary',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppTheme.spacing),
            DropdownButtonFormField<String>(
              decoration: AppTheme.formFieldDecoration.copyWith(
                labelText: 'Report Year',
              ),
              value: selectedYear,
              items: List.generate(6, (index) => (DateTime.now().year + index).toString())
                  .map((year) => DropdownMenuItem(
                        value: year,
                        child: Text(year),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onYearChange(value);
                }
              },
            ),
            const SizedBox(height: AppTheme.spacing),
            FilledButton.icon(
              onPressed: isGenerating ? null : () => _generateReport(context),
              style: AppTheme.filledButtonStyle,
              icon: isGenerating 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.summarize),
              label: Text(isGenerating ? 'Generating...' : 'Generate Report'),
            ),
          ],
        ),
      ),
    );
  }
} 