#!/usr/bin/env python3
"""
Script to check what programs exist in the database
"""

import requests

# Supabase configuration
SUPABASE_URL = "https://fwcqtjsqetqavdhkahzy.supabase.co"
SUPABASE_KEY = "sb_publishable_H6iglIKUpKGjz-sA6W2PGA_3p7vqL7G"
ORGANIZATION_ID = "C015857"

def check_programs():
    """Check what programs exist in the database"""
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}',
    }
    
    url = f"{SUPABASE_URL}/rest/v1/programs"
    params = {
        'organization_id': f'eq.{ORGANIZATION_ID}',
        'select': '*',
    }
    
    try:
        response = requests.get(url, headers=headers, params=params)
        
        if response.status_code == 200:
            programs = response.json()
            print(f"✅ Found {len(programs)} programs for organization {ORGANIZATION_ID}")
            
            for program in programs:
                print(f"   ID: {program.get('id', 'N/A')}")
                print(f"   Name: {program.get('name', 'N/A')}")
                print(f"   Category: {program.get('category', 'N/A')}")
                print("   ---")
        else:
            print(f"❌ Error: {response.status_code} - {response.text}")
            
    except Exception as e:
        print(f"❌ Exception: {e}")

if __name__ == "__main__":
    check_programs() 