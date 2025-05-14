import json
import os
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

def import_custom_programs(organization_id: str, json_file: str):
    # Initialize Firebase Admin SDK with the correct path to credentials
    cred_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 
                            'council-finance-firebase-adminsdk-e5auu-46ccb83881.json')
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)
    
    # Get Firestore client
    db = firestore.client()
    
    # Read the JSON file
    with open(json_file, 'r') as f:
        data = json.load(f)
    
    # Get the programs collection reference
    programs_ref = db.collection('organizations').document(organization_id).collection('programs')
    
    # Import each program
    for program in data['programs']:
        # Create a new document with auto-generated ID
        doc_ref = programs_ref.document()
        
        # Prepare program data
        program_data = {
            'id': doc_ref.id,
            'name': program['name'],
            'category': program['category'].lower(),  # Ensure lowercase to match app's format
            'isSystemDefault': False,
            'financialType': program['financialType'],
            'isEnabled': True,
            'isAssembly': False,  # These are council programs
            'createdAt': firestore.SERVER_TIMESTAMP
        }
        
        # Add the program to Firestore
        doc_ref.set(program_data)
        print(f"Added program: {program['name']}")

if __name__ == '__main__':
    # Import programs for Council 15857
    import_custom_programs(
        organization_id='C015857',
        json_file='assets/data/custom_programs.json'
    ) 