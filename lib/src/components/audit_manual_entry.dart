import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../reports/audit_field_map.dart';

class AuditManualEntry extends StatefulWidget {
  final Map<String, String> initialValues;
  final Map<String, String>? placeholderValues;
  final Function(Map<String, String>) onValuesChanged;

  const AuditManualEntry({
    super.key,
    required this.initialValues,
    this.placeholderValues,
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
          // Pass the values directly with PDF field names
          widget.onValuesChanged(_currentValues);
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
              'Schedule B — Cash Transactions (Treasurer)',
              ['Text61', 'Text62', 'Text63', 'Text64'],
              'Enter receipt values for the Treasurer',
              [
                'Cash on hand beginning of period*',
                'Received from financial secretary*',
                'Transfers from sav./other accts.*',
                'Interest earned*',
              ],
            ),
            const SizedBox(height: AppTheme.spacing),
            _buildSection(
              'Schedule B — Cash Transactions (Treasurer Disbursements)',
              ['Text66', 'Text67', 'Text68', 'Text69', 'Text70'],
              'Enter disbursement values for the Treasurer',
              [
                'Per capita: Supreme Council*',
                'State Council*',
                'General council expenses*',
                'Transfers to sav./other accts.*',
                'Miscellaneous*',
              ],
            ),
            const SizedBox(height: AppTheme.spacing),
            _buildSection(
              'Schedule C — Assets',
              [
                'Text73', 'Text74', 'Text75', 'Text76', 'Text77', 'Text78',
                'Text84', 'Text85', 'Text86'
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
              ],
            ),
            const SizedBox(height: AppTheme.spacing),
            _buildSection(
              'Schedule C — Liabilities',
              [
                'Text89', 'Text90', 'Text91', 'Text92', 'Text93', 'Text95', 'Text96',
                'Text97', 'Text98', 'Text99', 'Text100', 'Text101', 'Text102'
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
                'Liability 1 Name*',
                'Liability 1 Amount (USD)*',
                'Liability 2 Amount (USD)*',
                'Liability 3 Name*',
                'Liability 3 Amount (USD)*',
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
          
          // Get placeholder for specific fields
          String? placeholder;
          if (widget.placeholderValues != null) {
            if (fields[field] == 'Text64' && widget.placeholderValues!.containsKey('interest_earned')) {
              placeholder = 'Suggested: ${widget.placeholderValues!['interest_earned']}';
            } else if (fields[field] == 'Text66' && widget.placeholderValues!.containsKey('supreme_per_capita')) {
              placeholder = 'Suggested: ${widget.placeholderValues!['supreme_per_capita']}';
            } else if (fields[field] == 'Text67' && widget.placeholderValues!.containsKey('state_per_capita')) {
              placeholder = 'Suggested: ${widget.placeholderValues!['state_per_capita']}';
            }
          }
          
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
            child: TextFormField(
              controller: _controllers[fields[field]],
              decoration: AppTheme.formFieldDecoration.copyWith(
                labelText: displayLabel,
                hintText: placeholder ?? (isNameField ? 'Enter name/description' : 'Enter amount'),
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