#!/usr/bin/env python3
"""
Script to run SQL commands needed for CSV import
"""

import requests
import json

# Supabase configuration
SUPABASE_URL = "https://fwcqtjsqetqavdhkahzy.supabase.co"
SUPABASE_KEY = "sb_publishable_H6iglIKUpKGjz-sA6W2PGA_3p7vqL7G"

def run_sql_command(sql):
    """Run a SQL command via Supabase REST API"""
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal'
    }
    
    url = f"{SUPABASE_URL}/rest/v1/rpc/exec_sql"
    
    data = {
        'query': sql
    }
    
    try:
        response = requests.post(url, headers=headers, json=data)
        print(f"SQL Command Status: {response.status_code}")
        if response.status_code != 200:
            print(f"Error: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"Exception: {e}")
        return False

def main():
    """Run the necessary SQL commands"""
    print("Running SQL commands for CSV import...")
    
    # Command 1: Disable RLS
    print("\n1. Disabling RLS on finance_entries...")
    sql1 = "ALTER TABLE public.finance_entries DISABLE ROW LEVEL SECURITY;"
    success1 = run_sql_command(sql1)
    
    # Command 2: Create missing programs
    print("\n2. Creating missing programs...")
    sql2 = """
    INSERT INTO public.programs (id, organization_id, name, category, is_system_default, financial_type, is_enabled, is_assembly) VALUES
    ('C015857_football_crazr', 'C015857', 'Football Crazr', 'COUNCIL', false, 'both', true, false),
    ('C015857_donations_received', 'C015857', 'Donations Received', 'COMMUNITY', false, 'both', true, false),
    ('C015857_parish_breakfast', 'C015857', 'Parish Breakfast', 'COMMUNITY', false, 'both', true, false),
    ('C015857_parish_movie_knight', 'C015857', 'Parish Movie Knight', 'FAMILY', false, 'both', true, false),
    ('C015857_chairperson_fund', 'C015857', 'Chairperson Fund', 'FAITH', false, 'both', true, false),
    ('C015857_st_martin_hot_chocolate', 'C015857', 'St Martin of Tours Hot Chocolate', 'FAITH', false, 'both', true, false),
    ('C015857_unbound', 'C015857', 'Unbound', 'LIFE', false, 'both', true, false),
    ('C015857_council_insurance', 'C015857', 'Council Insurance', 'COUNCIL', false, 'both', true, false),
    ('C015857_membership_expenses', 'C015857', 'Membership Expenses', 'COUNCIL', false, 'both', true, false),
    ('C015857_interest', 'C015857', 'Interest', 'COUNCIL', false, 'both', true, false),
    ('C015857_disaster_relief', 'C015857', 'Disaster Relief', 'COMMUNITY', false, 'both', true, false),
    ('C015857_seminarian_donations', 'C015857', 'Seminarian Donations', 'FAITH', false, 'both', true, false),
    ('C015857_movie_night', 'C015857', 'Movie Night', 'COMMUNITY', false, 'both', true, false),
    ('C015857_rsvp_fundraiser', 'C015857', 'RSVP Fundraiser', 'COMMUNITY', false, 'both', true, false),
    ('C015857_convention_expenses', 'C015857', 'Convention Expenses', 'COUNCIL', false, 'both', true, false),
    ('C015857_fish_fry', 'C015857', 'Fish Fry', 'COMMUNITY', false, 'both', true, false),
    ('C015857_conference_refund', 'C015857', 'Conference Refund', 'COUNCIL', false, 'both', true, false),
    ('C015857_per_capita_state', 'C015857', 'Per Capita - State', 'COUNCIL', false, 'both', true, false),
    ('C015857_postage', 'C015857', 'Postage', 'COUNCIL', false, 'both', true, false),
    ('C015857_membership_dues', 'C015857', 'Membership Dues', 'COUNCIL', false, 'both', true, false)
    ON CONFLICT (id) DO NOTHING;
    """
    success2 = run_sql_command(sql2)
    
    if success1 and success2:
        print("\n✅ SQL commands completed successfully!")
        print("You can now run the import script.")
    else:
        print("\n❌ Some SQL commands failed. Please check the errors above.")

if __name__ == "__main__":
    main() 