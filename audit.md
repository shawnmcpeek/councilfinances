# Audit Form Field Notes and Calculation Rules

**General Rule:**
- All calculations and totals are for the selected financial period only:
  - January–June (for the June form)
  - July–December (for the December form)
- Never include transactions from outside the selected period (e.g., no September transactions in the January–June report).
-Text1 will use the user's defined Council number as found in their firestore profile data.
-Text2 and Text4 we will eventually need to figure out how to auto fill this with correct information. 
Text3 will be from the year the user provides so if they select 2025 it will be 25, if 2032 it will be 32.

---

## Fields to Ignore
- **Text5–Text48, Checkbox49:**
  - For manual-entry councils only. Not supported in this app.

---

## Field Logic and Calculations

### Text50
- User-provided value (manual entry).

### Text51
- Total of all recorded entries for "Council - Membership Dues" (for the selected period).

### Text52–Text57 (Top Income Programs)
- Group all income transactions (excluding membership dues) by program.
- Sum the total for each program (e.g., "Coats for Kids" = $2500 from 4 transactions, not 4 separate entries).
- Identify the top 2 income programs by total amount:
  - **Text52:** Top program name
  - **Text53:** Top program total
  - **Text54:** Second program name
  - **Text55:** Second program total
- Any remaining income programs (beyond the top 2, and not membership dues) are grouped as "Other":
  - **Text56:** "Other"
  - **Text57:** Total of all other income programs

### Text58
- Calculated as: `Text50 + Text51 + Text53 + Text55 + Text57`

### Text59
- User-provided value (manual entry).

### Text60
- Calculated as: `Text58 - Text59`

### Text61–Text63
- No action for now; will revisit later.

### Text64
- Total from "Council - Interest Earned" (default council program).

### Text65
- Calculated as: `Text62 + Text63 + Text64`

### Text66
- Total from "Council - Supreme Per Capita".

### Text67
- Total from "Council - State Per Capita".

### Text68
- Total of all other council category programs not already listed, plus any custom council categories.

### Text69
- Manual entry.

### Text70
- 0 for now (may become manual entry).

### Text71
- Calculated as: `Text68 + Text69 + Text70`

### Text72
- Calculated as: `Text65 - Text71`

### Text73
- Should equal `Text72`.

### Text74–Text76
- Manual entry (future implementation may automate).

### Text77
- Manual entry.

### Text78
- Manual entry for now. (Future: `Text77 * Membership Dues Rate`; will require user-entered dues rate.)

### Text79
- Sum of `Text73` through `Text78`.

### Text80
- Pulls value from `Text103`.

### Text83
- Calculated as: `Text79 - Text80`.

### Text84–Text87
- Manual entry (future implementation may automate).

### Text88
- Sum of `Text83` through `Text87`.

### Text89–Text93
- Manual entry. (Text92: manual entry, but default to 0 if left blank.)

### Text95
- Manual entry.

### Text96
- Manual entry for now. (Future: `Text95 * membership dues rate`.)

### Text97–Text102
- Manual entry.

### Text103
- Sum of: `Text89 + Text90 + Text91 + Text92 + Text93 + Text94 + Text95 + Text96 + Text98 + Text100 + Text102`.

### Text104–Text110
- Manual entry.

---

## Program Notes
- Default council programs to include:
  - Membership Dues
  - Postage
  - Insurance
  - Membership Expenses
  - Advertising
  - Supreme Per Capita
  - State Per Capita
  - Conference Expenses
  - Interest Earned

- Program category name should change based on organization type:
  - "Council" for councils
  - "Assembly" for assemblies

---

## Manual Entry Fields
- Text50, Text59, Text69, Text74–Text78, Text84–Text87, Text89–Text93, Text95–Text97, Text99, Text101, Text104–Text110

---

## Future Implementation Notes
- Some manual entry fields may be automated in future versions (e.g., Text78, Text96, Text74–Text76, Text84–Text87).
- Membership Dues Rate will be a user-provided field for future calculations. 