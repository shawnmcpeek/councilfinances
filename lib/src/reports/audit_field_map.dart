// Removed: import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show DateTimeRange;

class AuditFieldMap {
  // Map field IDs to their corresponding data points and calculation rules
  static const Map<String, String> fields = {
    // Basic Info
    'Text1': 'council_number',  // From user profile
    'Text2': 'council_city',    // From user profile - council location
    'Text3': 'year',           // From selected year (last 2 digits)
    'Text4': 'organization_name', // From user profile

    // Income Section
    'Text50': 'manual_income_1',  // Manual entry
    'Text51': 'membership_dues',  // Auto-calculated from transactions
    'Text52': 'top_program_1_name', // Auto-calculated from transactions
    'Text53': 'top_program_1_amount', // Auto-calculated from transactions
    'Text54': 'top_program_2_name', // Auto-calculated from transactions
    'Text55': 'top_program_2_amount', // Auto-calculated from transactions
    'Text56': 'other_programs_name', // Always "Other"
    'Text57': 'other_programs_amount', // Auto-calculated from transactions
    'Text58': 'total_income', // Auto-calculated: Text50 + Text51 + Text53 + Text55 + Text57
    'Text59': 'manual_income_2', // Manual entry
    'Text60': 'cash_on_hand_end_period', // Auto-calculated: Text58 - Text59 (cash on hand at end of period)

    // Schedule B - Treasurer Section
    'Text61': 'treasurer_cash_beginning', // Manual entry: Cash on hand beginning of period
    'Text62': 'treasurer_received_financial_secretary', // Manual entry: Received from financial secretary
    'Text63': 'treasurer_transfers_from_savings', // Manual entry: Transfers from sav./other accts.
    'Text64': 'treasurer_interest_earned', // Manual entry with placeholder from Supabase
    'Text65': 'treasurer_total_receipts', // Auto-calculated: Text62 + Text63 + Text64
    'Text66': 'treasurer_supreme_per_capita', // Manual entry with placeholder from Supabase
    'Text67': 'treasurer_state_per_capita', // Manual entry with placeholder from Supabase
    'Text68': 'total_assets_verify', // Auto-calculated: Text83 + Text87
    'Text69': 'treasurer_transfers_to_savings', // Manual entry: Transfers to sav./other accts.
    'Text70': 'treasurer_miscellaneous', // Manual entry
    'Text71': 'treasurer_total_disbursements', // Auto-calculated: Text66 + Text67 + Text68 + Text69 + Text70
    'Text72': 'treasurer_net_balance', // Auto-calculated: Text61 + Text65 - Text71
    'Text73': 'net_council_verify', // Manual entry: Undeposited funds

    // Membership Section
    'Text74': 'manual_membership_1', // Manual entry
    'Text75': 'manual_membership_2', // Manual entry
    'Text76': 'manual_membership_3', // Manual entry
    'Text77': 'membership_count', // Manual entry
    'Text78': 'membership_dues_total', // Manual entry (future: Text77 * dues rate)
    'Text79': 'total_membership', // Auto-calculated: Text73 + Text74 + Text75 + Text76 + Text77 + Text78
    'Text80': 'total_disbursements', // Pulls from Text103
    'Text83': 'net_membership', // Auto-calculated: Text79 - Text80

    // Disbursements Section
    'Text84': 'manual_disbursement_1', // Manual entry
    'Text85': 'manual_disbursement_2', // Manual entry
    'Text86': 'manual_disbursement_3', // Manual entry
    'Text87': 'total_assets', // Auto-calculated: Text64 + Text65 + Text66
    'Text88': 'total_disbursements_verify', // Auto-calculated: Text83 + Text84 + Text85 + Text86

    // Additional Fields
    'Text89': 'manual_field_1', // Manual entry
    'Text90': 'manual_field_2', // Manual entry
    'Text91': 'manual_field_3', // Manual entry
    'Text92': 'manual_field_4', // Manual entry (defaults to 0)
    'Text93': 'manual_field_5', // Manual entry
    'Text95': 'manual_field_6', // Manual entry
    'Text96': 'manual_field_7', // Manual entry (future: Text95 * dues rate)
    'Text97': 'manual_field_8', // Manual entry
    'Text98': 'liability_1_amount', // Manual entry
    'Text99': 'liability_1_name', // Manual entry
    'Text100': 'liability_2_amount', // Manual entry
    'Text101': 'liability_3_name', // Manual entry
    'Text102': 'liability_3_amount', // Manual entry
    'Text103': 'total_liabilities', // Auto-calculated: Text98 + Text100 + Text102
    'Text104': 'manual_field_14', // No data from app
    'Text105': 'manual_field_15', // No data from app
    'Text106': 'manual_field_16', // No data from app
    'Text107': 'manual_field_17', // No data from app
    'Text108': 'manual_field_18', // No data from app
    'Text109': 'manual_field_19', // No data from app
    'Text110': 'manual_field_20', // No data from app
  };

  // Fields that require manual entry
  static const List<String> manualEntryFields = [
    'Text50', 'Text59', 
    'Text61', 'Text62', 'Text63', 'Text64', 'Text66', 'Text67', 'Text69', 'Text70',
    'Text73',
    'Text74', 'Text75', 'Text76', 'Text77', 'Text78',
    'Text84', 'Text85', 'Text86',
    'Text89', 'Text90', 'Text91', 'Text92', 'Text93',
    'Text95', 'Text96', 'Text97', 'Text98', 'Text99',
    'Text100', 'Text101', 'Text102'
  ];

  // Fields that are auto-calculated
  static const List<String> autoCalculatedFields = [
    'Text51', 'Text52', 'Text53', 'Text54', 'Text55',
    'Text56', 'Text57', 'Text58', 'Text60', 'Text65', 
    'Text68', 'Text71', 'Text72', 'Text87',
    'Text79', 'Text80', 'Text83', 'Text88', 'Text103',
    'Text104', 'Text105', 'Text106', 'Text107', 'Text108', 'Text109', 'Text110'
  ];

  // Default council programs to track
  static const List<String> defaultCouncilPrograms = [
    'Membership Dues',
    'Postage',
    'Council Insurance',
    'Membership Expenses',
    'Advertising',
    'Per Capita - Supreme',
    'Per Capita - State',
    'Convention',
    'Interest'
  ];

  // Helper method to get the date range for a period
  static DateTimeRange getDateRangeForPeriod(String period, int year) {
    final startDate = period == 'June' 
        ? DateTime(year, 1, 1) 
        : DateTime(year, 7, 1);
    final endDate = period == 'June'
        ? DateTime(year, 6, 30)
        : DateTime(year, 12, 31);
    return DateTimeRange(start: startDate, end: endDate);
  }

  // Helper method to format currency values
  static String formatCurrency(double value) {
    return value.toStringAsFixed(2);
  }

  // Helper method to get the last two digits of a year
  static String getYearSuffix(int year) {
    return year.toString().substring(2);
  }
} 