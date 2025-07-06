import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../reports/audit_field_map.dart';

class AuditManualEntry extends StatefulWidget {
  final Map<String, String> initialValues;
  final Function(Map<String, String>) onValuesChanged;

  const AuditManualEntry({
    super.key,
    required this.initialValues,
    required this.onValuesChanged,
  });

  @override
  State<AuditManualEntry> createState() => _AuditManualEntryState();
}

class _AuditManualEntryState extends State<AuditManualEntry> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _currentValues = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (final field in AuditFieldMap.manualEntryFields) {
      final initialValue = widget.initialValues[field] ?? '';
      _controllers[field] = TextEditingController(text: initialValue);
      _currentValues[field] = initialValue;
      
      // Add listener to detect changes
      _controllers[field]!.addListener(() {
        final newValue = _controllers[field]!.text;
        if (_currentValues[field] != newValue) {
          _currentValues[field] = newValue;
          // Map Text69 and Text70 to manual_expense_1 and manual_expense_2 for backend
          final mappedValues = Map<String, String>.from(_currentValues);
          if (mappedValues.containsKey('Text69')) {
            mappedValues['manual_expense_1'] = mappedValues['Text69'] ?? '';
          }
          if (mappedValues.containsKey('Text70')) {
            mappedValues['manual_expense_2'] = mappedValues['Text70'] ?? '';
          }
          widget.onValuesChanged(mappedValues);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
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
              'Audit Report Data Entry',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            Text(
              'Enter values for the semi-annual audit report. Fields marked with * are required.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppTheme.spacing),
            _buildSection(
              'Schedule B — Cash Transactions (Financial Secretary)',
              ['Text50', 'Text59'],
              'Enter cash transaction values for the Financial Secretary',
              [
                'Cash on hand beginning of period*',
                'Transferred to treasurer*',
              ],
            ),
            const SizedBox(height: AppTheme.spacing),
            _buildSection(
              'Schedule B — Cash Transactions (Treasurer Disbursements)',
              ['Text69', 'Text70'],
              'Enter disbursement values for the Treasurer',
              [
                'General council expenses*',
                'Transfers to sav./other accts.*',
              ],
            ),
            const SizedBox(height: AppTheme.spacing),
            _buildSection(
              'Schedule C — Assets',
              [
                'Text73', 'Text74', 'Text75', 'Text76', 'Text77', 'Text78',
                'Text84', 'Text85', 'Text86', 'Text87', 'Text100', 'Text101'
              ],
              'Enter asset values',
              [
                'Undeposited funds*',
                'Bank — Checking acct.*',
                'Bank — Savings acct.*',
                'Bank — Money market accts.*',
                'How many members have outstanding dues',
                'Total amount of outstanding dues (USD)',
                'Other asset*',
                'Short term CD*',
                'Money Market Mutual Funds*',
                'Misc. Asset 1 Name',
                'Misc. Asset 1 Amount (USD)',
                'Misc. Asset 2 Name',
                'Misc. Asset 2 Amount (USD)',
              ],
            ),
            const SizedBox(height: AppTheme.spacing),
            _buildSection(
              'Schedule C — Liabilities',
              [
                'Text89', 'Text90', 'Text91', 'Text92', 'Text93', 'Text95', 'Text96',
                'Text97', 'Text98', 'Text99', 'Text102', 'Text104', 'Text105'
              ],
              'Enter liability values',
              [
                'Due Supreme Council: Per capita*',
                'Due Supreme Council: Supplies*',
                'Due Supreme Council: Catholic advertising*',
                'Due Supreme Council: Other*',
                'Due State Council*',
                'Advance payments by members (number)*',
                'Advance payments by members (amount)*',
                'Misc. Liability 1 Name',
                'Misc. Liability 1 Amount (USD)',
                'Misc. Liability 2 Name',
                'Misc. Liability 2 Amount (USD)',
                'Misc. Liability 3 Name',
                'Misc. Liability 3 Amount (USD)',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> fields, String subtitle, List<String> labels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppTheme.smallSpacing),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: AppTheme.smallSpacing),
        ...fields.asMap().entries.map((entry) {
          final field = entry.key;
          final label = labels[field];
          final isRequired = label.endsWith('*');
          final displayLabel = isRequired ? label.substring(0, label.length - 1) : label;
          final isNameField = label.toLowerCase().contains('name');
          final isAmountField = label.toLowerCase().contains('amount');
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
            child: TextFormField(
              controller: _controllers[fields[field]],
              decoration: AppTheme.formFieldDecoration.copyWith(
                labelText: displayLabel,
                hintText: isNameField ? 'Enter name/description' : 'Enter amount',
                suffixText: isAmountField ? 'USD' : null,
                helperText: isRequired ? 'Required field' : null,
              ),
              keyboardType: isNameField ? TextInputType.text : const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: isNameField
                ? []
                : [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
              validator: (value) {
                if (isRequired && (value == null || value.isEmpty)) {
                  return 'This field is required';
                }
                if (!isNameField && value != null && value.isNotEmpty) {
                  final number = double.tryParse(value);
                  if (number == null) {
                    return 'Please enter a valid number';
                  }
                  if (number < 0) {
                    return 'Amount cannot be negative';
                  }
                }
                return null;
              },
            ),
          );
        }),
      ],
    );
  }
} 