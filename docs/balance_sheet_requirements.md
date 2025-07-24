# Balance Sheet Feature Requirements

## Overview
Create a dynamic balance sheet feature that aggregates all financial entries (income and expense) by category and by month, similar to the provided Google Sheet/pdf. This feature will allow users to view, print, and export a summary of financial activity, matching the clarity and utility of the current manual process.

---

## 1. Data Model & Sources

### FinanceEntry Model (already exists)
- **Fields:**
  - `id`: String
  - `date`: DateTime
  - `program`: Program (see below)
  - `amount`: double
  - `paymentMethod`: String
  - `checkNumber`: String? (nullable)
  - `description`: String
  - `isExpense`: bool

### Program Model (already exists)
- **Fields:**
  - `id`: String
  - `name`: String
  - `category`: String (used for grouping)
  - `financialType`: enum (expenseOnly, incomeOnly, both)
  - `isEnabled`: bool

### Data Source
- All financial entries are stored and retrieved via `FinanceService`.
- Entries are already categorized by program and have a date for monthly grouping.

---

## 2. Aggregation Logic

### Grouping
- **Primary Group:** By `program.category` (or `program.name` for more granularity)
- **Secondary Group:** By month and year (`entry.date.month`, `entry.date.year`)

### Calculations
- For each (category, month) pair:
  - **Total Income:** Sum of `amount` where `isExpense == false`
  - **Total Expense:** Sum of `amount` where `isExpense == true`
  - **Net:** Income - Expense (optional, for display)
- **Grand Totals:**
  - Per category (across all months)
  - Per month (across all categories)
  - Overall totals (all categories, all months)

---

## 3. User Interface (UI/UX)

### Main View
- **Table/Grid Layout:**
  - **Rows:** Categories (or Programs)
  - **Columns:** Months (Jan, Feb, ..., Dec)
  - **Cells:** Show total income and total expense for that category/month (e.g., `+100 / -50`)
  - **Grand Total Row/Column:** For overall sums
- **Expandable Rows:** (Optional)
  - Allow users to expand a category to see individual entries for that month
- **Filters:**
  - By year
  - By category
  - By type (income/expense)
- **Sorting:**
  - By category, by total, by month, etc.

### Additional Features
- **Export/Print:**
  - Export the summary as PDF or CSV
  - Print-friendly view
- **Reconciliation:** (Optional)
  - Mark months as reconciled/approved
  - Add notes/comments per month
- **Visuals:** (Optional)
  - Charts/graphs for trends

---

## 4. Permissions & Roles
- Only users with appropriate roles (e.g., treasurer, admin) can:
  - Add/edit/delete entries
  - Mark months as reconciled
  - Export/print summaries
- Regular users can view summaries but not modify data

---

## 5. Workflow
1. **Entry Submission:**
   - Users submit income/expense entries via existing forms
2. **Aggregation:**
   - System aggregates entries in real time for the summary view
3. **Review:**
   - Users view the balance sheet summary, filter/sort as needed
4. **Export/Print:**
   - Users export or print the summary for reporting
5. **Reconciliation:** (Optional)
   - Treasurer/admin marks months as reconciled when matched to official reports

---

## 6. Technical Considerations
- **Performance:**
  - Efficient aggregation for large datasets
- **Data Integrity:**
  - Handle corrections/edits gracefully
  - Prevent double-counting
- **UI Consistency:**
  - Use global styling and button patterns
- **Testing:**
  - Unit and integration tests for aggregation logic and UI

---

## 7. Migration/Import (Optional)
- Tool to import historical data from Google Sheets (CSV import)

---

## 8. Open Questions (to clarify before implementation)
- Should categories be user-editable or fixed?
- Should the summary show both category and program breakdowns?
- What level of detail is needed in the export (just totals, or individual entries as well)?
- What permissions should be required for each action?
- Any specific formatting requirements for the PDF/print output?

---

## 9. Example Table Layout

| Category   | Jan Income | Jan Expense | Feb Income | Feb Expense | ... | Total Income | Total Expense | Net Total |
|------------|------------|-------------|------------|-------------|-----|--------------|---------------|-----------|
| Dues       | $100       | $0          | $120       | $0          | ... | $220         | $0            | $220      |
| Fundraiser | $500       | $200        | $0         | $50         | ... | $500         | $250          | $250      |
| ...        | ...        | ...         | ...        | ...         | ... | ...          | ...           | ...       |
| **Totals** | $600       | $200        | $120       | $50         | ... | $720         | $250          | $470      |

---

## 10. References
- See `FinanceEntry`, `Program`, `ExpenseEntry`, `IncomeEntry`, and `TransactionHistory` for current data and entry logic.
- See Google Sheet/pdf for desired output format and aggregation logic. 