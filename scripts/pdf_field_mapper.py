from pdfrw import PdfReader, PdfWriter
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter
import io
import json

def get_field_type(field):
    """Helper function to determine field type"""
    if not hasattr(field, 'FT'):
        return 'unknown'
    ft = str(field.FT)
    if ft == '/Tx':
        return 'text'
    elif ft == '/Btn':
        if hasattr(field, 'Ff') and field.Ff and int(str(field.Ff)) & (1 << 16):  # Check if radio button flag is set
            return 'radio'
        return 'checkbox'
    elif ft == '/Ch':
        if hasattr(field, 'Ff') and field.Ff and int(str(field.Ff)) & (1 << 17):  # Check if multi-select flag is set
            return 'multiselect'
        return 'dropdown'
    elif ft == '/Sig':
        return 'signature'
    return ft

def get_field_value(field):
    """Helper function to get field value"""
    if not hasattr(field, 'V'):
        return None
    value = str(field.V)
    if value.startswith('(') and value.endswith(')'):
        value = value[1:-1]
    return value

def get_field_name(field):
    """Helper function to get field name"""
    if not hasattr(field, 'T'):
        return None
    name = str(field.T)
    if name.startswith('(') and name.endswith(')'):
        name = name[1:-1]
    return name

def create_field_visualization(fields, output_path, input_path):
    """Create a visual representation of field locations"""
    packet = io.BytesIO()
    can = canvas.Canvas(packet, pagesize=letter)
    
    # Draw field locations and names
    for field_name, info in fields.items():
        if 'position' in info:
            pos = info['position']
            x, y = pos['x'], pos['y']
            width, height = pos['width'], pos['height']
            
            # Draw rectangle around field
            can.rect(x, y, width, height)
            
            # Draw field name
            can.drawString(x, y + height + 2, field_name)
    
    can.save()
    packet.seek(0)
    
    # Create a new PDF with field visualization
    new_pdf = PdfReader(packet)
    existing_pdf = PdfReader(input_path)
    output = PdfWriter()
    
    # Add the field visualization layer to the first page
    page = existing_pdf.pages[0]
    page.merge_page(new_pdf.pages[0])
    output.add_page(page)
    
    # Add remaining pages as is
    for page in existing_pdf.pages[1:]:
        output.add_page(page)
    
    # Save the result
    with open(output_path, 'wb') as f:
        output.write(f)

def map_pdf_fields(input_path: str, output_path: str):
    """
    Analyzes a PDF form and extracts detailed information about each field.
    Also creates a visual representation of field locations.
    """
    print(f"Reading PDF: {input_path}")
    
    reader = PdfReader(input_path)
    field_mapping = {}
    
    def process_field(field):
        if not hasattr(field, 'T'):
            return
            
        field_name = get_field_name(field)
        if not field_name:
            return
            
        # Get field type
        field_type = get_field_type(field)
        
        # Get field value
        field_value = get_field_value(field)
        
        # Get field position
        position = None
        if hasattr(field, 'Rect'):
            rect = [float(x) for x in field.Rect]
            if len(rect) == 4:
                position = {
                    'x': rect[0],
                    'y': rect[1],
                    'width': rect[2] - rect[0],
                    'height': rect[3] - rect[1]
                }
        
        # Get flags safely
        flags = 0
        if hasattr(field, 'Ff') and field.Ff:
            try:
                flags = int(str(field.Ff))
            except (ValueError, TypeError):
                pass
        
        # Build field info dictionary
        field_info = {
            'type': field_type,
            'value': field_value,
            'position': position,
            'required': bool(flags & 1),
            'read_only': bool(flags & 2),
            'default_value': str(field.DV) if hasattr(field, 'DV') else '',
            'flags': flags
        }
        
        # For choice fields (dropdown/multiselect), get options
        if field_type in ['dropdown', 'multiselect'] and hasattr(field, 'Opt'):
            options = []
            for opt in field.Opt:
                if hasattr(opt, 'decode'):
                    options.append(opt.decode('utf-8'))
                else:
                    options.append(str(opt))
            field_info['options'] = options
        
        # Clean up empty values
        field_info = {k: v for k, v in field_info.items() if v is not None and v != ''}
        
        field_mapping[field_name] = field_info
        
        # Print field information
        print(f"\nField: {field_name}")
        print("-" * 30)
        for key, value in field_info.items():
            if value:  # Only print non-empty values
                if key == 'position':
                    print(f"position: x={value['x']:.1f}, y={value['y']:.1f}, width={value['width']:.1f}, height={value['height']:.1f}")
                else:
                    print(f"{key}: {value}")
    
    # Process all fields in the PDF
    for page in reader.pages:
        if hasattr(page, 'Annots') and page.Annots:
            for annot in page.Annots:
                if hasattr(annot, 'FT'):  # This is a form field
                    try:
                        process_field(annot)
                    except Exception as e:
                        print(f"Error processing field: {str(e)}")
                        continue
    
    # Save the field mapping
    mapping_path = output_path.replace('.pdf', '_mapping.json')
    with open(mapping_path, 'w') as f:
        json.dump(field_mapping, f, indent=2)
    print(f"\nField mapping saved to: {mapping_path}")
    
    # Create visual representation
    try:
        create_field_visualization(field_mapping, output_path, input_path)
        print(f"Created visual field map: {output_path}")
    except Exception as e:
        print(f"Error creating visual field map: {str(e)}")
    
    return field_mapping

if __name__ == "__main__":
    input_pdf = "../assets/forms/audit2_1295_p.pdf"
    output_pdf = "audit2_1295_p_mapped.pdf"
    map_pdf_fields(input_pdf, output_pdf) 