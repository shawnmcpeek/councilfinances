#!/usr/bin/env python3
"""
Test script to verify that financial data was imported successfully
"""

import requests

# Supabase configuration
SUPABASE_URL = "https://fwcqtjsqetqavdhkahzy.supabase.co"
SUPABASE_KEY = "sb_publishable_H6iglIKUpKGjz-sA6W2PGA_3p7vqL7G"
ORGANIZATION_ID = "C015857"

def test_import():
    """Test that data was imported successfully"""
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}',
    }
    
    url = f"{SUPABASE_URL}/rest/v1/finance_entries"
    params = {
        'organization_id': f'eq.{ORGANIZATION_ID}',
    }
    
    try:
        response = requests.get(url, headers=headers, params=params)
        
        if response.status_code == 200:
            data = response.json()
            count = len(data) if isinstance(data, list) else 0
            print(f"✅ Successfully connected to Supabase!")
            print(f"📊 Found {count} finance entries for organization {ORGANIZATION_ID}")
            
            if count > 0:
                print("✅ Import appears to be successful!")
                
                # Get a sample entry
                sample_url = f"{SUPABASE_URL}/rest/v1/finance_entries"
                sample_params = {
                    'organization_id': f'eq.{ORGANIZATION_ID}',
                    'limit': '1',
                }
                
                sample_response = requests.get(sample_url, headers=headers, params=sample_params)
                if sample_response.status_code == 200:
                    sample_data = sample_response.json()
                    if sample_data:
                        sample = sample_data[0]
                        print(f"📝 Sample entry:")
                        print(f"   Description: {sample.get('description', 'N/A')}")
                        print(f"   Amount: ${sample.get('amount', 0):.2f}")
                        print(f"   Is Expense: {sample.get('is_expense', False)}")
                        print(f"   Payment Method: {sample.get('payment_method', 'N/A')}")
                        print(f"   Date: {sample.get('date', 'N/A')}")
            else:
                print("❌ No entries found - import may have failed")
        else:
            print(f"❌ Error connecting to Supabase: {response.status_code} - {response.text}")
            
    except Exception as e:
        print(f"❌ Exception: {e}")

if __name__ == "__main__":
    test_import() 