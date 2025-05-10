from PyPDF2 import PdfReader
import json

def read_mapped_pdf(pdf_path: str) -> dict:
    """
    Reads the mapped PDF and creates a mapping of field names to their full values.
    """
    print(f"Reading mapped PDF: {pdf_path}")
    
    # Open the PDF
    reader = PdfReader(pdf_path)
    fields = reader.get_fields()
    
    if not fields:
        print("No form fields found")
        return {}
    
    # Create mapping of field names to their values
    field_mapping = {}
    for field_name, field in fields.items():
        # Get the full value, not just what's visible
        value = field.get('/V', '')
        field_mapping[field_name] = value
    
    return field_mapping

def save_mapping(mapping: dict, output_path: str):
    """Saves the field mapping to a JSON file"""
    with open(output_path, 'w') as f:
        json.dump(mapping, f, indent=2)

if __name__ == "__main__":
    mapped_pdf = "audit2_1295_p_mapped.pdf"
    output_json = "audit2_1295_field_mapping.json"
    
    # Read the mapped PDF
    mapping = read_mapped_pdf(mapped_pdf)
    
    # Save the mapping
    save_mapping(mapping, output_json)
    print(f"\nField mapping saved to: {output_json}")
    
    # Print the mapping
    print("\nField Mapping:")
    print("=" * 50)
    for field_name, value in mapping.items():
        print(f"{field_name}: {value}") 