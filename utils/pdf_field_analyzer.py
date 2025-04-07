#!/usr/bin/env python3
from PyPDF2 import PdfReader, PdfWriter
import argparse
import os
import json

def analyze_pdf_fields(input_path, output_path, mapping_path):
    """
    Read a PDF form, fill each field with its own field name,
    and save to a new PDF for field mapping analysis.
    """
    # Read the PDF
    reader = PdfReader(input_path)
    writer = PdfWriter()
    
    # Get the first page (assuming form is one page)
    page = reader.pages[0]
    writer.add_page(page)
    
    # Get form fields
    fields = reader.get_fields()
    
    print(f"\nAnalyzing PDF form: {input_path}")
    print("\nFound fields:")
    
    # Create a dictionary to store field info
    field_info = {}
    
    for field_name in fields.keys():
        field = fields[field_name]
        print(f"Field: {field_name}")
        field_info[field_name] = {
            'type': field['/FT'] if '/FT' in field else 'Unknown',
            'name': field_name,
        }
        # Fill each field with its own name
        writer.update_page_form_field_values(
            writer.pages[0], {field_name: field_name}
        )
    
    # Save the filled form
    with open(output_path, 'wb') as output_file:
        writer.write(output_file)
    
    # Save field mapping to JSON file
    with open(mapping_path, 'w') as mapping_file:
        json.dump(field_info, mapping_file, indent=2)
    
    print(f"\nAnalysis complete.")
    print(f"- Check {output_path} to see field names in their locations")
    print(f"- Check {mapping_path} for the field mapping data")

def main():
    # Get the directory where this script is located
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Default paths
    default_input = os.path.join(script_dir, 'fraternal_survey1728_p.pdf')
    default_output = os.path.join(script_dir, 'fraternal_survey1728_p_analyzed.pdf')
    default_mapping = os.path.join(script_dir, 'field_mapping.json')

    parser = argparse.ArgumentParser(description='Analyze PDF form fields')
    parser.add_argument('--input_pdf', 
                       default=default_input,
                       help='Path to the input PDF form (default: fraternal_survey1728_p.pdf)')
    parser.add_argument('--output_pdf',
                       default=default_output,
                       help='Path for the output PDF with field names (default: fraternal_survey1728_p_analyzed.pdf)')
    parser.add_argument('--mapping_json',
                       default=default_mapping,
                       help='Path for the JSON field mapping (default: field_mapping.json)')
    args = parser.parse_args()
    
    analyze_pdf_fields(args.input_pdf, args.output_pdf, args.mapping_json)

if __name__ == '__main__':
    main() 