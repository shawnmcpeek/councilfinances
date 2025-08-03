from pdfrw import PdfReader, PdfWriter
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter
import io
import json

def test_visualization():
    """Test the visualization function step by step"""
    print("Testing PDF visualization...")
    
    # Load the mapping data
    with open('audit1_1295_p_mapped_mapping.json', 'r') as f:
        field_mapping = json.load(f)
    
    print(f"Loaded {len(field_mapping)} fields")
    
    # Test creating the canvas
    try:
        packet = io.BytesIO()
        can = canvas.Canvas(packet, pagesize=letter)
        print("✓ Canvas created successfully")
        
        # Draw a few test fields
        count = 0
        for field_name, info in field_mapping.items():
            if 'position' in info and count < 5:  # Just test first 5 fields
                pos = info['position']
                x, y = pos['x'], pos['y']
                width, height = pos['width'], pos['height']
                
                # Draw rectangle around field
                can.rect(x, y, width, height)
                
                # Draw field name
                can.drawString(x, y + height + 2, field_name)
                count += 1
                print(f"✓ Drew field {field_name}")
        
        can.save()
        packet.seek(0)
        print("✓ Canvas saved successfully")
        
        # Test reading the original PDF
        input_path = "../assets/forms/audit1_1295_p.pdf"
        existing_pdf = PdfReader(input_path)
        print(f"✓ Original PDF loaded successfully ({len(existing_pdf.pages)} pages)")
        
        # Test reading the new PDF
        new_pdf = PdfReader(packet)
        print(f"✓ New PDF loaded successfully ({len(new_pdf.pages)} pages)")
        
        # Test merging
        output = PdfWriter()
        page = existing_pdf.pages[0]
        page.merge_page(new_pdf.pages[0])
        output.add_page(page)
        print("✓ Pages merged successfully")
        
        # Test saving
        output_path = "test_mapped.pdf"
        with open(output_path, 'wb') as f:
            output.write(f)
        print(f"✓ Output saved to {output_path}")
        
    except Exception as e:
        print(f"✗ Error: {str(e)}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_visualization() 