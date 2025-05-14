import os
import firebase_admin
from firebase_admin import credentials, firestore

def create_missing_programs(organization_id: str):
    print(f"Creating missing programs for organization {organization_id}")
    
    # Initialize Firebase Admin SDK
    cred_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 
                            'council-finance-firebase-adminsdk-e5auu-46ccb83881.json')
    print(f"Using credentials from {cred_path}")
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)
    
    # Get Firestore client
    db = firestore.client()
    print("Connected to Firestore")
    
    # Get programs collection reference
    programs_ref = db.collection('organizations').document(organization_id).collection('programs')
    
    # Define missing programs
    missing_programs = [
        {
            'name': 'Dues',
            'category': 'Council',
            'isSystemDefault': True,
            'financialType': 'both',
            'isEnabled': True
        },
        {
            'name': 'Council Insurance',
            'category': 'Council',
            'isSystemDefault': True,
            'financialType': 'expenseOnly',
            'isEnabled': True
        },
        {
            'name': 'Interest',
            'category': 'Council',
            'isSystemDefault': True,
            'financialType': 'incomeOnly',
            'isEnabled': True
        },
        {
            'name': 'Convention',
            'category': 'Council',
            'isSystemDefault': True,
            'financialType': 'expenseOnly',
            'isEnabled': True
        },
        {
            'name': 'Conference',
            'category': 'Council',
            'isSystemDefault': True,
            'financialType': 'expenseOnly',
            'isEnabled': True
        }
    ]
    
    # Add each program
    for program in missing_programs:
        try:
            # Check if program already exists
            query = programs_ref.where('name', '==', program['name']).limit(1)
            docs = query.get()
            
            if not docs:
                # Create new program
                doc_ref = programs_ref.document()
                program['id'] = doc_ref.id
                doc_ref.set(program)
                print(f"Created program: {program['name']}")
            else:
                print(f"Program already exists: {program['name']}")
                
        except Exception as e:
            print(f"Error creating program {program['name']}: {str(e)}")
    
    print("\nProgram creation complete")

if __name__ == '__main__':
    # Create missing programs for Council 15857
    create_missing_programs('C015857') 