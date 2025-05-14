# Treasurer Role Implementation Plan

## Overview
This document outlines the detailed implementation plan for the Treasurer role, focusing on a separate reconciliation component within the finance module. The plan covers data models, UI/UX, workflow, permissions, and integration points to ensure a robust, user-friendly, and auditable system for managing council finances.

---

## 1. Roles & Permissions
- **Treasurer**: Power user with full access to finance features, including transaction entry, account management, and reconciliation.
- **Financial Secretary**: Can enter transactions but cannot reconcile or assign to accounts.
- **Admin**: Full access, including unlocking reconciled periods.
- **Regular User**: View-only access to summaries and reports.

---

## 2. Data Model Changes

### 2.1 Account Model
- `id: String`
- `name: String`
- `type: String` (e.g., Checking, Savings)
- `startingBalance: double`
- `currentBalance: double` (calculated)
- `createdBy: String`
- `createdAt: DateTime`

### 2.2 FinanceEntry Model (existing, with additions)
- `id: String`
- `date: DateTime`
- `program: Program`
- `amount: double`
- `paymentMethod: String`
- `checkNumber: String?`
- `description: String`
- `isExpense: bool`
- `enteredBy: String`
- `accountId: String?` (assigned during reconciliation or entry)
- `isReconciled: bool` (per transaction)
- `reconciledBy: String?`
- `reconciledAt: DateTime?`

### 2.3 ReconciliationRecord (per account/month)
- `id: String`
- `accountId: String`
- `month: int`
- `year: int`
- `isReconciled: bool`
- `reconciledBy: String?`
- `reconciledAt: DateTime?`
- `notes: String?`

---

## 3. UI/UX Design

### 3.1 Navigation
- Add a "Reconciliation" tab or subscreen under the Finance section.
- Only visible to Treasurer/Admin roles.

### 3.2 Reconciliation Screen
- **Account Selector:** Dropdown populated with accounts managed by the Treasurer. If only one account, auto-select.
- **Month/Year Selector:** Choose the period to reconcile.
- **Transaction List:**
  - List all transactions for the selected account and month.
  - Each row: date, description, amount, program, enteredBy, isExpense/income, account dropdown (if not set), checkbox/toggle for "Reconciled".
  - If account is not set, Treasurer selects from dropdown (auto-populated from their accounts).
  - If transaction is missing (e.g., interest), Treasurer can add it directly from this screen.
- **Bulk Actions:**
  - "Mark all as reconciled" button (if all transactions are checked).
  - Add reconciliation notes for the period.
- **Status Indicator:**
  - Show if the month/account is fully reconciled, by whom, and when.
- **Locking:**
  - Once reconciled, period is locked for edits unless unlocked by Admin.

### 3.3 Transaction Entry
- Treasurer can add income/expense transactions from both the main finance screen and the reconciliation screen.
- Account selection required for each transaction (dropdown, auto-selected if only one account).

### 3.4 Audit Trail
- Display who entered and who reconciled each transaction.
- Show reconciliation history per account/month.

---

## 4. Workflow

1. **Account Setup:**
   - Treasurer creates and manages accounts via profile or account management screen.
2. **Transaction Entry:**
   - Financial Secretary and Treasurer enter transactions (income/expense) as they occur.
   - Account can be left unset by FS; Treasurer assigns during reconciliation.
3. **Reconciliation:**
   - Treasurer navigates to Reconciliation screen, selects account and month.
   - Reviews all transactions, assigns accounts if needed, checks off as reconciled.
   - Adds missing transactions (e.g., interest, card expenses).
   - Adds notes if needed.
   - Marks month/account as fully reconciled (locks period).
4. **Reporting:**
   - Balance sheet and other reports reflect reconciled status and account assignments.
5. **Unlocking (Admin):**
   - Admin can unlock a reconciled period for corrections if necessary.

---

## 5. Security & Permissions
- Only Treasurer/Admin can access reconciliation features and assign accounts.
- Only Admin can unlock reconciled periods.
- All actions logged for audit purposes.

---

## 6. Future Enhancements
- Import and auto-match bank statements for semi-automated reconciliation.
- Partial reconciliation (per transaction, not just per month/account).
- Visual indicators for unreconciled transactions.
- Reconciliation summary dashboard.

---

## 7. References
- See `balance_sheet_requirements.md` for aggregation and reporting logic.
- See `FinanceEntry`, `Account`, and `Program` models for data structure.
- See current finance and profile screens for UI patterns. 