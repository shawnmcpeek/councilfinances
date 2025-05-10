import json
from typing import Dict, List, Tuple
import re

def create_field_mapping(purposes_path: str) -> Dict[str, str]:
    """
    Create a mapping between field names and their actual purposes.
    """
    print(f"Reading purposes from: {purposes_path}")
    
    # Load purposes
    with open(purposes_path, 'r') as f:
        purposes = json.load(f)
    
    # Define field categories
    categories = {
        'date': {
            'day': r'day|date',
            'month': r'month',
            'year': r'year|20\s+_+',
        },
        'council_info': {
            'council_name': r'council\s+name|name\s+of\s+council',
            'council_number': r'council\s+number|number\s+of\s+council',
            'location': r'location|city|state',
        },
        'financial': {
            'cash': r'cash|funds?|money',
            'assets': r'assets?',
            'liabilities': r'liabilit(y|ies)',
            'total': r'total',
            'balance': r'balance',
            'amount': r'amount|\$',
        },
        'signature': {
            'grand_knight': r'grand\s+knight',
            'trustee': r'trustee',
            'signature': r'sign(ed|ature)',
        }
    }
    
    field_mapping = {}
    
    # Process each field
    for field_name, field_info in purposes.items():
        # Skip fields without nearby text
        if 'nearby_text' not in field_info:
            continue
        
        # Get nearby text as a single string
        text = ' '.join(field_info['nearby_text']).lower()
        
        # Get field position
        pos = field_info['position']
        y_pos = pos['y']
        
        # Determine field purpose based on nearby text and position
        purpose = None
        max_score = 0
        
        # Check each category
        for category, patterns in categories.items():
            for purpose_name, pattern in patterns.items():
                matches = len(re.findall(pattern, text))
                if matches > max_score:
                    max_score = matches
                    purpose = f"{category}_{purpose_name}"
        
        # If no specific purpose found, use the likely purposes
        if not purpose and 'likely_purposes' in field_info:
            likely_purposes = field_info['likely_purposes']
            if likely_purposes:
                purpose = likely_purposes[0]
        
        # Store the mapping
        field_mapping[field_name] = {
            'purpose': purpose,
            'type': field_info['type'],
            'position': field_info['position'],
            'nearby_text': field_info['nearby_text']
        }
        
        # Print field information
        print(f"\nField: {field_name}")
        print("-" * 30)
        print(f"Type: {field_info['type']}")
        print(f"Purpose: {purpose}")
        print("Nearby text:")
        print(f"  {' '.join(field_info['nearby_text'])}")
    
    # Save the mapping
    output_path = purposes_path.replace('_purposes.json', '_mapping_final.json')
    with open(output_path, 'w') as f:
        json.dump(field_mapping, f, indent=2)
    print(f"\nField mapping saved to: {output_path}")
    
    return field_mapping

if __name__ == "__main__":
    purposes_file = "audit2_1295_p_purposes.json"
    create_field_mapping(purposes_file) 