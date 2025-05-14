import json
import os
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

def parse_amount(amount_str):
    # Remove $ and convert to float
    if isinstance(amount_str, str):
        amount_str = amount_str.replace('$', '').replace(',', '')
    return float(amount_str)

def parse_date(date_str):
    # Handle different date formats
    try:
        # Try MM/DD/YYYY
        return datetime.strptime(date_str, '%m/%d/%Y')
    except ValueError:
        # Try MM/DD/YY
        return datetime.strptime(date_str, '%m/%d/%y')

def get_program_id(db, organization_id, program_name):
    # Query programs collection to find matching program
    programs_ref = db.collection('organizations').document(organization_id).collection('programs')
    query = programs_ref.where('name', '==', program_name).limit(1)
    docs = query.get()
    
    if not docs:
        raise Exception(f"Program not found: {program_name}")
    
    return docs[0].id

def get_program_data(db, organization_id, program_name):
    # Query programs collection to find matching program
    programs_ref = db.collection('organizations').document(organization_id).collection('programs')
    # Get all programs and find a case-insensitive match
    docs = programs_ref.get()
    
    for doc in docs:
        data = doc.to_dict()
        if data['name'].lower() == program_name.lower():
            return {
                'id': doc.id,
                'name': data['name'],  # Use the exact name from Firestore
                'category': data['category'],  # Use the exact category from Firestore
                'isSystemDefault': data.get('isSystemDefault', False),
                'financialType': data.get('financialType', 'both'),
                'isEnabled': data.get('isEnabled', True)
            }
    
    raise Exception(f"Program not found: {program_name}")

def import_financial_entries(organization_id: str, json_file: str):
    print(f"Starting import from {json_file} for organization {organization_id}")
    
    # Initialize Firebase Admin SDK
    cred_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 
                            'council-finance-firebase-adminsdk-e5auu-46ccb83881.json')
    print(f"Using credentials from {cred_path}")
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)
    
    # Get Firestore client
    db = firestore.client()
    print("Connected to Firestore")
    
    # Get finance collection reference
    finance_ref = db.collection('organizations').document(organization_id).collection('finance')
    
    # Read and process JSON file
    print(f"Opening JSON file: {json_file}")
    with open(json_file, 'r') as f:
        entries = json.load(f)
    
    row_count = 0
    imported_count = 0
    
    for entry in entries:
        row_count += 1
        try:
            # Skip entries without required fields
            required_fields = ['date', 'amount', 'description', 'programId', 'programName', 'paymentMethod']
            if not all(field in entry for field in required_fields):
                print(f"Skipping entry {row_count}: Missing required fields")
                continue
            
            # Get the year from the timestamp
            year = datetime.fromtimestamp(entry['date']['_seconds']).year
            
            # Determine if it's an expense based on amount sign
            is_expense = entry['amount'] < 0
            entry_type = 'expenses' if is_expense else 'income'
            
            # Get program data
            program_data = get_program_data(db, organization_id, entry['programName'])
            
            # Create a new document with auto-generated ID
            doc_ref = finance_ref.document(entry_type).collection(str(year)).document()
            
            # Convert timestamp objects using firestore client
            entry_data = {
                'id': doc_ref.id,
                'date': firestore.SERVER_TIMESTAMP,  # This will be converted to the current server time
                'program': program_data,
                'amount': abs(entry['amount']),
                'paymentMethod': entry['paymentMethod'],
                'description': entry['description'],
                'isExpense': is_expense,
                'createdAt': firestore.SERVER_TIMESTAMP,
                'updatedAt': firestore.SERVER_TIMESTAMP,
                'createdBy': entry['createdBy'],
                'updatedBy': entry['updatedBy']
            }
            
            # Set the actual date from the entry data
            doc_ref.set(entry_data)
            doc_ref.update({
                'date': datetime.fromtimestamp(entry['date']['_seconds']),
                'createdAt': datetime.fromtimestamp(entry['createdAt']['_seconds']),
                'updatedAt': datetime.fromtimestamp(entry['updatedAt']['_seconds'])
            })
            
            # Add check number if payment method is check
            if entry['paymentMethod'].lower() == 'check' and 'checkNumber' in entry:
                entry_data['checkNumber'] = entry['checkNumber']
            
            imported_count += 1
            print(f"  ✓ Imported entry {row_count} successfully")
            
        except Exception as e:
            print(f"  ✗ Error processing entry {row_count}: {str(e)}")
            continue
    
    print(f"\nImport complete:")
    print(f"  Total entries processed: {row_count}")
    print(f"  Successfully imported: {imported_count}")

if __name__ == '__main__':
    # Import financial entries for Council 15857
    json_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'financial_entries.json')
    import_financial_entries(
        organization_id='C015857',
        json_file=json_path
    ) 