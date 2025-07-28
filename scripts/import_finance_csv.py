#!/usr/bin/env python3
"""
Import CSV financial data into Supabase finance_entries table
Converts the exported Firebase data to match the Supabase schema
"""

import csv
import json
import os
import sys
from datetime import datetime
from typing import Dict, List, Optional
import requests

# Supabase configuration
SUPABASE_URL = "https://fwcqtjsqetqavdhkahzy.supabase.co"
SUPABASE_KEY = "sb_publishable_H6iglIKUpKGjz-sA6W2PGA_3p7vqL7G"
ORGANIZATION_ID = "C015857"

def parse_amount(amount_str: str) -> float:
    """Parse amount string to float, handling various formats"""
    if not amount_str or amount_str.strip() == '':
        return 0.0
    
    # Remove quotes, commas, and dollar signs
    amount_str = amount_str.replace('"', '').replace(',', '').replace('$', '')
    
    # Handle negative amounts (expenses)
    is_negative = amount_str.startswith('-')
    if is_negative:
        amount_str = amount_str[1:]
    
    try:
        amount = float(amount_str)
        return -amount if is_negative else amount
    except ValueError:
        print(f"Warning: Could not parse amount '{amount_str}', using 0.0")
        return 0.0

def parse_date(date_str: str) -> str:
    """Parse date string to ISO format"""
    if not date_str or date_str.strip() == '':
        return datetime.now().isoformat()
    
    try:
        # Handle various date formats
        if '/' in date_str:
            # Format: 1/1/2025, 1/14/25, etc.
            if len(date_str.split('/')[-1]) == 2:
                # Convert 2-digit year to 4-digit
                parts = date_str.split('/')
                year = parts[-1]
                if int(year) < 50:  # Assume 20xx for years < 50
                    year = '20' + year
                else:
                    year = '19' + year
                date_str = '/'.join(parts[:-1] + [year])
            
            # Parse the date
            date_obj = datetime.strptime(date_str, '%m/%d/%Y')
        else:
            # Try other formats
            date_obj = datetime.fromisoformat(date_str)
        
        return date_obj.isoformat()
    except ValueError as e:
        print(f"Warning: Could not parse date '{date_str}', using current date: {e}")
        return datetime.now().isoformat()

def map_transaction_type_to_payment_method(transaction_type: str) -> str:
    """Map transaction type to payment method"""
    mapping = {
        'Check': 'check',
        'Cash': 'cash',
        'Debit Card': 'debitCard',
        'Square': 'square',
        'Interest': 'cash',  # Interest is typically cash
    }
    return mapping.get(transaction_type, 'cash')

def determine_program_from_category(category: str) -> Dict[str, str]:
    """Determine program ID and name from category"""
    # Remove R- or E- prefix and clean up
    clean_category = category.replace('R-', '').replace('E-', '')
    
    # Map categories to program IDs and names
    program_mapping = {
        'Membership Dues': {
            'id': 'membership_dues',
            'name': 'Membership Dues'
        },
        'Council - Per Capita': {
            'id': 'per_capita_state',
            'name': 'Per Capita - State'
        },
        'Council - Postage': {
            'id': 'postage',
            'name': 'Postage'
        },
        'Council - Football Crazr': {
            'id': 'football_crazr',
            'name': 'Football Crazr'
        },
        'Community - Parish Breakfast': {
            'id': 'parish_breakfast',
            'name': 'Parish Breakfast'
        },
        'Family - Parish Movie Knight': {
            'id': 'parish_movie_knight',
            'name': 'Parish Movie Knight'
        },
        'Faith - Chairperson Fund': {
            'id': 'chairperson_fund',
            'name': 'Chairperson Fund'
        },
        'Faith - St Martin of Tours Hot Chocolate': {
            'id': 'st_martin_hot_chocolate',
            'name': 'St Martin of Tours Hot Chocolate'
        },
        'Life - unbound': {
            'id': 'unbound',
            'name': 'Unbound'
        },
        'Council - Council Insurance, Trade Name, bank, po box': {
            'id': 'council_insurance',
            'name': 'Council Insurance'
        },
        'Council-Membership Expenses': {
            'id': 'membership_expenses',
            'name': 'Membership Expenses'
        },
        'Council - Interest earned': {
            'id': 'interest',
            'name': 'Interest'
        },
        'Community - Disaster Relief': {
            'id': 'disaster_relief',
            'name': 'Disaster Relief'
        },
        'Faith - Seminarian Donations': {
            'id': 'seminarian_donations',
            'name': 'Seminarian Donations'
        },
        'Community - Movie Night': {
            'id': 'movie_night',
            'name': 'Movie Night'
        },
        'Community - RSVP Fundraiser': {
            'id': 'rsvp_fundraiser',
            'name': 'RSVP Fundraiser'
        },
        'Council - Convention Expenses': {
            'id': 'convention_expenses',
            'name': 'Convention Expenses'
        },
        'Donations Received': {
            'id': 'donations_received',
            'name': 'Donations Received'
        },
        'Community - Fish Fry': {
            'id': 'fish_fry',
            'name': 'Fish Fry'
        },
        'KofC Conference Refund': {
            'id': 'conference_refund',
            'name': 'Conference Refund'
        },
    }
    
    return program_mapping.get(clean_category, {
        'id': 'other',
        'name': clean_category
    })

def create_finance_entry(row: Dict[str, str], index: int) -> Dict:
    """Create a finance entry from CSV row"""
    category = row.get('Category', '').strip()
    date_str = row.get('Date', '').strip()
    recipient = row.get('Recipient/Cause', '').strip()
    amount_str = row.get('Amount', '').strip()
    transaction_type = row.get('Transaction Type', '').strip()
    
    # Parse amount and determine if it's an expense
    amount = parse_amount(amount_str)
    is_expense = amount < 0
    if is_expense:
        amount = abs(amount)  # Store positive amount, use is_expense flag
    
    # Get program info
    program_info = determine_program_from_category(category)
    
    # Create unique ID
    entry_id = f"{ORGANIZATION_ID}_{program_info['id']}_{index}"
    
    # Create the finance entry
    entry = {
        'id': entry_id,
        'organization_id': ORGANIZATION_ID,
        'program_id': program_info['id'],
        'program_name': program_info['name'],
        'is_expense': is_expense,
        'amount': amount,
        'description': recipient if recipient else f"{category} transaction",
        'date': parse_date(date_str),
        'payment_method': map_transaction_type_to_payment_method(transaction_type),
        'check_number': None,  # CSV doesn't have check numbers
        'created_at': datetime.now().isoformat(),
        'updated_at': datetime.now().isoformat(),
        'created_by': None,  # Null for CSV imports
        'updated_by': None,  # Null for CSV imports
    }
    
    return entry

def import_to_supabase(entries: List[Dict]) -> None:
    """Import entries to Supabase"""
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal'
    }
    
    url = f"{SUPABASE_URL}/rest/v1/finance_entries"
    
    print(f"Importing {len(entries)} entries to Supabase...")
    
    # Import in batches to avoid overwhelming the API
    batch_size = 50
    for i in range(0, len(entries), batch_size):
        batch = entries[i:i + batch_size]
        
        try:
            response = requests.post(
                url,
                headers=headers,
                json=batch
            )
            
            if response.status_code == 201:
                print(f"Successfully imported batch {i//batch_size + 1} ({len(batch)} entries)")
            else:
                print(f"Error importing batch {i//batch_size + 1}: {response.status_code} - {response.text}")
                
        except Exception as e:
            print(f"Exception importing batch {i//batch_size + 1}: {e}")

def main():
    """Main function to import CSV data"""
    csv_file = "2025 Council 15857 Finances - Transactions.csv"
    
    if not os.path.exists(csv_file):
        print(f"Error: CSV file '{csv_file}' not found!")
        print("Please place the CSV file in the same directory as this script.")
        sys.exit(1)
    
    print(f"Reading CSV file: {csv_file}")
    
    entries = []
    with open(csv_file, 'r', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        
        for index, row in enumerate(reader):
            # Skip empty rows
            if not row.get('Category') or not row.get('Date'):
                continue
                
            try:
                entry = create_finance_entry(row, index)
                entries.append(entry)
                print(f"Processed row {index + 1}: {entry['description']} - ${entry['amount']:.2f}")
            except Exception as e:
                print(f"Error processing row {index + 1}: {e}")
                continue
    
    print(f"\nProcessed {len(entries)} entries")
    
    if entries:
        # Ask for confirmation before importing
        response = input(f"\nReady to import {len(entries)} entries to Supabase? (y/N): ")
        if response.lower() == 'y':
            import_to_supabase(entries)
            print("\nImport completed!")
        else:
            print("Import cancelled.")
    else:
        print("No entries to import.")

if __name__ == "__main__":
    main() 