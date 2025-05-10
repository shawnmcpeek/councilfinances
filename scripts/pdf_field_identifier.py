from PyPDF2 import PdfReader, PdfWriter

def fill_fields_with_names(input_path: str, output_path: str):
    """
    Creates a new PDF where each form field is filled with its own name
    for easy identification.
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
        print("No form fields found")
        return
        
    print(f"\nFound {len(fields)} fields. Filling each with its name...")
    
    # Fill each field with its name
    for field_name in fields:
        try:
            writer.update_page_form_field_values(
                writer.pages[0],  # Assuming all fields are on first page
                {field_name: field_name}
            )
        except Exception as e:
            print(f"Error filling field {field_name}: {str(e)}")
            
    # Save the filled PDF
    print(f"\nSaving filled PDF to: {output_path}")
    with open(output_path, "wb") as output_file:
        writer.write(output_file)
    
    print("Done! Open the output PDF to see field names in their locations.")

if __name__ == "__main__":
    input_pdf = "audit2_1295_p.pdf"
    output_pdf = "audit2_1295_p_identified.pdf"
    fill_fields_with_names(input_pdf, output_pdf) 