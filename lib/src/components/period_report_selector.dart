import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PeriodReportSelector extends StatelessWidget {
  const PeriodReportSelector({Key? key}) : super(key: key);

  void _navigateToAuditData(BuildContext context) {
    Navigator.of(context).pushNamed('/auditData');
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
              'Audit Report',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            Text(
              'Generate semi-annual audit report Form 1295',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppTheme.spacing),
            FilledButton.icon(
              onPressed: () => _navigateToAuditData(context),
              style: AppTheme.filledButtonStyle,
              icon: const Icon(Icons.summarize),
              label: const Text('Build Audit Report'),
            ),
          ],
        ),
      ),
    );
  }
} 