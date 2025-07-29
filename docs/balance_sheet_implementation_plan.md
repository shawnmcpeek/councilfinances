# Balance Sheet Implementation Plan

## Overview
Create a comprehensive balance sheet report that displays financial data in a structured format with program income and expenses organized by month, with yearly totals.

## Current State Analysis
- ✅ Finance entries exist in `finance_entries` table
- ✅ Program model with categories and financial types
- ✅ Finance service for data retrieval
- ✅ Reports screen with access control
- ❌ No balance sheet component exists
- ❌ No data aggregation service for balance sheet

## Data Structure Requirements

### Input Data
- **Source**: `finance_entries` table via `FinanceService`
- **Key Fields**:
  - `date`: DateTime (for monthly grouping)
  - `amount`: double
  - `is_expense`: bool (income vs expense)
  - `program_id`: String
  - `program_name`: String
  - `organization_id`: String

### Program Selection Logic
- **Primary**: Show all programs with financial activity in the selected year
- **Secondary**: Include currently enabled programs (as fallback)
- **Filtering**: Programs with only income appear only in income section, programs with only expenses appear only in expense section

### Output Structure
```dart
class BalanceSheetData {
  final String year;
  final List<BalanceSheetRow> incomeRows;
  final List<BalanceSheetRow> expenseRows;
  final Map<int, double> monthlyIncomeTotals; // month -> total
  final Map<int, double> monthlyExpenseTotals; // month -> total
  final double yearlyIncomeTotal;
  final double yearlyExpenseTotal;
  final double yearlyNetTotal; // income - expenses
}

class BalanceSheetRow {
  final String programName;
  final String programId;
  final Map<int, double> monthlyAmounts; // month -> amount (0.00 if no data)
  final double yearlyTotal;
}
```

## Implementation Steps

### Phase 1: Data Aggregation Service
1. **Create `BalanceSheetService`**
   - Method: `getBalanceSheetData(String organizationId, String year)`
   - Aggregates finance entries by program and month
   - Separates income and expense data
   - Calculates monthly and yearly totals

2. **Data Processing Logic**
   - Group entries by `program_id` and month
   - Filter by year and organization
   - Sum amounts for each (program, month) combination
   - Calculate running totals

### Phase 2: Balance Sheet Component
1. **Create `BalanceSheetWidget`**
   - Displays data in table format
   - Separate sections for income and expenses
   - Monthly columns (Jan-Dec)
   - Yearly totals column
   - Horizontal scrolling for mobile (no condensed view)
   - PDF-focused design (primary export target)

2. **UI Features**
   - Year selector dropdown (current year default, at least 1 previous year)
   - Loading states
   - Error handling
   - PDF export functionality (primary focus)
   - Zero values displayed as $0.00 for clarity

### Phase 3: Integration
1. **Add to Reports Screen**
   - Add balance sheet card to reports screen
   - Access control (full access only)
   - Consistent styling with other report components

2. **Navigation**
   - Add to reports screen layout
   - Follow existing patterns for organization toggle

## Technical Specifications

### Service Layer (`BalanceSheetService`)
```dart
class BalanceSheetService {
  Future<BalanceSheetData> getBalanceSheetData(
    String organizationId, 
    String year
  );
  
  Future<List<FinanceEntry>> _getFinanceEntriesForYear(
    String organizationId, 
    String year
  );
  
  BalanceSheetData _aggregateData(
    List<FinanceEntry> entries, 
    String year
  );
}
```

### Component Structure (`BalanceSheetWidget`)
```dart
class BalanceSheetWidget extends StatefulWidget {
  final String organizationId;
  final String selectedYear;
  
  // Methods:
  // - _loadBalanceSheetData()
  // - _buildIncomeSection()
  // - _buildExpenseSection()
  // - _buildMonthlyColumns()
  // - _buildTotalsRow()
}
```

### Data Display Format
```
INCOME SECTION
Program Name        | Jan   | Feb   | Mar   | ... | Dec   | Total
--------------------|-------|-------|-------|-----|-------|-------
Parish Breakfast    | 100.00| 120.00| 0.00  | ... | 150.00| 370.00
Movie Knight        | 500.00| 0.00  | 300.00| ... | 0.00  | 800.00
Fish Fry           | 0.00  | 0.00  | 0.00  | ... | 0.00  | 0.00
...                | ...   | ...   | ...   | ... | ...   | ...
Monthly Totals     | 600.00| 120.00| 300.00| ... | 150.00| 1170.00

EXPENSE SECTION
Program Name        | Jan   | Feb   | Mar   | ... | Dec   | Total
--------------------|-------|-------|-------|-----|-------|-------
Parish Breakfast    | 50.00 | 0.00  | 0.00  | ... | 0.00  | 50.00
Movie Knight        | 200.00| 50.00 | 100.00| ... | 75.00 | 425.00
Fish Fry           | 0.00  | 0.00  | 0.00  | ... | 0.00  | 0.00
...                | ...   | ...   | ...   | ... | ...   | ...
Monthly Totals     | 250.00| 50.00 | 100.00| ... | 75.00 | 475.00

NET POSITION        | 350.00| 70.00 | 200.00| ... | 75.00 | 695.00
```

## File Structure
```
lib/src/
├── services/
│   └── balance_sheet_service.dart     # Data aggregation
├── components/
│   └── balance_sheet_widget.dart      # Main component
└── screens/
    └── reports_screen.dart            # Integration point
```

## Access Control
- **Required Access**: Full access only
- **Check**: `_hasFinancialAccess()` method in reports screen
- **Organization**: Respects council/assembly toggle

## Styling & UX
- **Theme**: Use `AppTheme` constants for consistency
- **Mobile**: Horizontal scrolling, no condensed view
- **Loading**: Show spinner during data fetch
- **Empty States**: Show $0.00 for all cells when no data exists
- **Error Handling**: Display user-friendly error messages
- **PDF Focus**: Design optimized for PDF export

## Future Enhancements (Phase 4+)
1. **Export Functionality**
   - PDF export (primary focus)
   - Print-friendly view
   - CSV export (secondary)

2. **Advanced Features**
   - Drill-down to individual entries
   - Comparison with previous years
   - Budget vs actual comparisons
   - Charts and graphs

3. **Performance Optimizations**
   - Caching for frequently accessed data
   - Pagination for large datasets
   - Background data refresh

## Testing Strategy
1. **Unit Tests**
   - `BalanceSheetService` aggregation logic
   - Data transformation methods
   - Edge cases (empty data, single entries)

2. **Widget Tests**
   - Component rendering
   - User interactions
   - Loading and error states

3. **Integration Tests**
   - End-to-end data flow
   - Service integration

## Success Criteria
- [ ] Balance sheet displays correctly with sample data
- [ ] Income and expense sections are clearly separated
- [ ] Monthly columns show correct totals with $0.00 for empty cells
- [ ] Yearly totals are accurate in far-right column
- [ ] Component integrates seamlessly with reports screen
- [ ] Access control works properly (full access only)
- [ ] Horizontal scrolling works on mobile devices
- [ ] Loading and error states are handled gracefully
- [ ] Year selector defaults to current year with at least 1 previous year option
- [ ] Programs appear only in sections where they have financial activity

## Dependencies
- Existing `FinanceService` for data retrieval
- Existing `Program` model for program information
- Existing `AppTheme` for consistent styling
- Existing access control patterns from reports screen

## Timeline Estimate
- **Phase 1** (Service): 2-3 hours
- **Phase 2** (Component): 4-5 hours  
- **Phase 3** (Integration): 1-2 hours
- **Testing & Polish**: 2-3 hours
- **Total**: 9-13 hours

## Notes
- Follow existing code patterns and conventions
- Use existing error handling and logging patterns
- Maintain consistency with other report components
- Consider performance implications for large datasets
- Plan for future export functionality
- Data is fetched when component loads (not real-time updates)
- PDF export is the primary use case
- Zero values should be explicitly shown as $0.00 