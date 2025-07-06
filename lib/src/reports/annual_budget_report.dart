import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/annual_budget_screen.dart';

class AnnualBudgetReport extends StatelessWidget {
  final String organizationId;
  final String selectedYear;
  final bool isGenerating;
  final ValueChanged<bool> onGeneratingChange;
  final ValueChanged<String> onYearChange;

  const AnnualBudgetReport({
    super.key,
    required this.organizationId,
    required this.selectedYear,
    required this.isGenerating,
    required this.onGeneratingChange,
    required this.onYearChange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppTheme.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Annual Budget',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            Text(
              'Generate annual budget report',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppTheme.spacing),
            FilledButton.icon(
              onPressed: isGenerating ? null : () {
                final route = MaterialPageRoute<void>(
                  builder: (BuildContext context) => AnnualBudgetScreen(
                    organizationId: organizationId,
                  ),
                );
                Navigator.of(context).push(route);
              },
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
              label: Text(isGenerating ? 'Generating...' : 'Generate Annual Budget'),
            ),
          ],
        ),
      ),
    );
  }
} 