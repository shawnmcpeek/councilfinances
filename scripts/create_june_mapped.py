from pdfrw import PdfReader, PdfWriter
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter
from reportlab.lib.colors import red
import io
import json

def create_june_mapped_pdf():
    """Create the June mapped PDF with field names overlaid"""
    print("Creating June mapped PDF...")
    
    # Load the field mapping
    with open('audit1_1295_p_mapped_mapping.json', 'r') as f:
        field_mapping = json.load(f)
    
    # Create a canvas with field names
    packet = io.BytesIO()
    can = canvas.Canvas(packet, pagesize=letter)
    can.setStrokeColor(red)
    can.setFillColor(red)
    
    # Draw field locations and names
    for field_name, info in field_mapping.items():
        if 'position' in info:
            pos = info['position']
            x, y = pos['x'], pos['y']
            width, height = pos['width'], pos['height']
            
            # Draw rectangle around field
            can.rect(x, y, width, height)
            
            # Draw field name (smaller font)
            can.setFont("Helvetica", 6)
            can.drawString(x, y + height + 1, field_name)
    
    can.save()
    packet.seek(0)
    
    # Load the original June PDF
    input_path = "../assets/forms/audit1_1295_p.pdf"
    existing_pdf = PdfReader(input_path)
    
    # Create the new PDF with overlays
    new_pdf = PdfReader(packet)
    output = PdfWriter()
    
    # Merge the field visualization with the original PDF
    page = existing_pdf.pages[0]
    page.merge_page(new_pdf.pages[0])
    output.add_page(page)
    
    # Save the result
    output_path = "audit1_1295_p_mapped.pdf"
    with open(output_path, 'wb') as f:
        output.write(f)
    
    print(f"✓ June mapped PDF created: {output_path}")

if __name__ == "__main__":
    create_june_mapped_pdf() 