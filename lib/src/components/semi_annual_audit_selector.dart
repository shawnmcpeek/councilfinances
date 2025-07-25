import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SemiAnnualAuditSelector extends StatefulWidget {
  final bool isGenerating;
  final Function(String, int) onGenerate;

  const SemiAnnualAuditSelector({
    super.key,
    required this.isGenerating,
    required this.onGenerate,
  });

  @override
  State<SemiAnnualAuditSelector> createState() => _SemiAnnualAuditSelectorState();
}

class _SemiAnnualAuditSelectorState extends State<SemiAnnualAuditSelector> {
  String selectedPeriod = 'December';
  int selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppTheme.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Semi-Annual Audit Report',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            Text(
              'Generate Form 1295 semi-annual audit report',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppTheme.spacing),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: AppTheme.formFieldDecoration.copyWith(
                      labelText: 'Report Period End',
                    ),
                    value: selectedPeriod,
                    items: const [
                      DropdownMenuItem(value: 'June', child: Text('June')),
                      DropdownMenuItem(value: 'December', child: Text('December')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedPeriod = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppTheme.spacing),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: AppTheme.formFieldDecoration.copyWith(
                      labelText: 'Report Year',
                    ),
                    value: selectedYear,
                    items: List.generate(6, (index) => (DateTime.now().year + index))
                        .map((year) => DropdownMenuItem(
                              value: year,
                              child: Text(year.toString()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedYear = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing),
            FilledButton.icon(
              onPressed: widget.isGenerating ? null : _generateReport,
              style: AppTheme.filledButtonStyle,
              icon: widget.isGenerating 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.summarize),
              label: Text(widget.isGenerating ? 'Generating...' : 'Generate Audit Report'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateReport() async {
    if (widget.isGenerating) return;
    widget.onGenerate(selectedPeriod, selectedYear);
  }
} 