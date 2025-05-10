from PyPDF2 import PdfReader, PdfWriter
import json
from datetime import datetime

def fill_pdf_form(input_path: str, output_path: str, data: dict):
    """
    Fill out a PDF form with the provided data.
    """
    print(f"Reading PDF: {input_path}")
    
    # Open the PDF
    reader = PdfReader(input_path)
    writer = PdfWriter()
    
    # Copy all pages to the writer
    for page in reader.pages:
        writer.add_page(page)
    
    # Get form fields
    fields = reader.get_fields()
    if not fields:
        print("No form fields found in the PDF.")
        return
    
    print(f"\nFound {len(fields)} form fields.")
    
    # Fill each field with data
    for field_name, field in fields.items():
        if field_name in data:
            try:
                writer.update_page_form_field_values(
                    writer.pages[0],  # Assuming all fields are on the first page
                    {field_name: str(data[field_name])}
                )
                print(f"Filled field: {field_name} = {data[field_name]}")
            except Exception as e:
                print(f"Error filling field {field_name}: {str(e)}")
    
    # Save the filled form
    with open(output_path, 'wb') as f:
        writer.write(f)
    print(f"\nFilled form saved to: {output_path}")

def create_sample_data():
    """
    Create sample data for testing.
    """
    return {
        'Text1': 'Sample Council',
        'Text2': datetime.now().strftime('%d'),  # Day
        'Text3': datetime.now().strftime('%B'),  # Month
        'Text4': datetime.now().strftime('%Y'),  # Year
        # Add more fields as needed
    }

if __name__ == "__main__":
    input_pdf = "audit2_1295_p.pdf"
    output_pdf = "audit2_1295_p_filled.pdf"
    
    # Create sample data
    data = create_sample_data()
    
    # Fill the form
    fill_pdf_form(input_pdf, output_pdf, data) 