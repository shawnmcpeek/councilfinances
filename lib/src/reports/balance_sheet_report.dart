import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'balance_sheet_report_service.dart';

class BalanceSheetReport extends StatelessWidget {
  final String organizationId;
  final String selectedYear;
  final bool isGenerating;
  final ValueChanged<bool> onGeneratingChange;
  final ValueChanged<String> onYearChange;

  const BalanceSheetReport({
    super.key,
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
      final service = BalanceSheetReportService(FirebaseFirestore.instance);
      await service.generateBalanceSheetReport(organizationId, selectedYear);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Balance sheet generated successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating balance sheet: ${e.toString()}')),
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
              'Balance Sheet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            Text(
              'Generate annual financial balance sheet',
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
              label: Text(isGenerating ? 'Generating...' : 'Generate Balance Sheet'),
            ),
          ],
        ),
      ),
    );
  }
} 