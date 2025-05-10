from PyPDF2 import PdfReader
import json
from datetime import datetime

def read_pdf_form(input_path: str, mapping_path: str = None):
    """
    Reads values from a filled PDF form and returns them in a structured format.
    If a mapping file is provided, it will be used to interpret the fields.
    """
    print(f"Reading PDF: {input_path}")
    
    # Load field mapping if provided
    field_mapping = None
    if mapping_path:
        try:
            with open(mapping_path, 'r') as f:
                field_mapping = json.load(f)
            print(f"Loaded field mapping from: {mapping_path}")
        except Exception as e:
            print(f"Error loading mapping file: {str(e)}")
    
    # Read the PDF
    reader = PdfReader(input_path)
    fields = reader.get_fields()
    
    if not fields:
        print("No form fields found in the PDF.")
        return {}
    
    print(f"\nFound {len(fields)} form fields.")
    
    # Extract values
    values = {}
    for field_name, field in fields.items():
        try:
            value = field.get('/V', '')
            if isinstance(value, bytes):
                try:
                    value = value.decode('utf-8')
                except:
                    value = str(value)
            
            # For checkbox fields, convert to boolean
            if field_mapping and field_mapping.get(field_name, {}).get('type') == 'checkbox':
                value = bool(value)
            
            values[field_name] = value
            
            # Print field value if not empty
            if value:
                print(f"{field_name}: {value}")
                
        except Exception as e:
            print(f"Error reading field {field_name}: {str(e)}")
            continue
    
    # Save the extracted values
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_path = f"extracted_values_{timestamp}.json"
    with open(output_path, 'w') as f:
        json.dump(values, f, indent=2)
    print(f"\nExtracted values saved to: {output_path}")
    
    return values

if __name__ == "__main__":
    input_pdf = "audit2_1295_p.pdf"  # Replace with your filled PDF
    mapping_file = "audit2_1295_p_mapped_mapping.json"
    read_pdf_form(input_pdf, mapping_file) 