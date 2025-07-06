import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../reports/audit_field_map.dart';

class AuditCalculatedFields extends StatelessWidget {
  final Map<String, String> values;

  const AuditCalculatedFields({
    super.key,
    required this.values,
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
              'Calculated Fields',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            Text(
              'These fields are automatically calculated based on your financial records.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppTheme.spacing),
            _buildSection(
              context,
              'Schedule B — Income',
              [
                ('Text51', 'Membership Dues'),
                ('Text52', 'Top Program Name'),
                ('Text53', 'Top Program Amount'),
                ('Text54', 'Second Program Name'),
                ('Text55', 'Second Program Amount'),
                ('Text56', 'Other Programs'),
                ('Text57', 'Other Programs Amount'),
                ('Text58', 'Total Income'),
                ('Text60', 'Net Income'),
              ],
            ),
            const SizedBox(height: AppTheme.spacing),
            _buildSection(
              context,
              'Schedule B — Interest and Per Capita',
              [
                ('Text64', 'Interest Earned'),
                ('Text65', 'Total Interest'),
                ('Text66', 'Supreme Per Capita'),
                ('Text67', 'State Per Capita'),
                ('Text68', 'Other Council Programs'),
                ('Text71', 'Total Expenses'),
                ('Text72', 'Net Council'),
                ('Text73', 'Net Council Verification'),
              ],
            ),
            const SizedBox(height: AppTheme.spacing),
            _buildSection(
              context,
              'Schedule C — Assets and Liabilities',
              [
                ('Text79', 'Total Current Assets'),
                ('Text80', 'Total Current Liabilities'),
                ('Text83', 'Net Membership'),
                ('Text88', 'Total Disbursements Verification'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<(String, String)> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppTheme.smallSpacing),
        ...fields.map((field) {
          final (fieldId, label) = field;
          final value = values[fieldId] ?? '0.00';
          final isAmount = !label.toLowerCase().contains('name');
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  child: Text(
                    isAmount ? '\$$value' : value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
} 