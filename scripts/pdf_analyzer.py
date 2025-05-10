from PyPDF2 import PdfReader
import pdfplumber
import sys
import json
from typing import Dict, Any

def get_field_context(pdf_path: str, page_num: int, rect: list, margin: int = 20) -> str:
    """Extract text near a field's rectangle to identify its purpose"""
    if not rect:
        return ""
    
    try:
        with pdfplumber.open(pdf_path) as pdf:
            page = pdf.pages[page_num]
            x1, y1, x2, y2 = rect
            
            # Extract words near the field
            words = page.extract_words()
            nearby_words = []
            
            for word in words:
                word_x = (word['x0'] + word['x1']) / 2
                word_y = (word['y0'] + word['y1']) / 2
                
                # Check if word is near the field
                if (x1 - margin <= word_x <= x2 + margin and
                    y1 - margin <= word_y <= y2 + margin):
                    nearby_words.append(word['text'])
            
            return ' '.join(nearby_words)
    except Exception as e:
        print(f"Error getting context: {str(e)}")
        return ""

def analyze_pdf_form(pdf_path: str) -> Dict[str, Any]:
    """
    Analyzes a PDF form and returns detailed information about its fields.
    
    Args:
        pdf_path: Path to the PDF file
        
    Returns:
        Dictionary containing form field information
    """
    try:
        pdf = PdfReader(pdf_path)
        fields = pdf.get_fields()
        
        if not fields:
            print(f"No form fields found in {pdf_path}")
            return {}
            
        # Create a detailed analysis of each field
        field_analysis = {}
        for field_name, field_properties in fields.items():
            # Get the page number
            page_ref = field_properties.get('/P')
            page_num = 0 if page_ref is None else pdf.get_page_number(page_ref)
            
            # Get field rectangle
            rect = field_properties.get('/Rect', [])
            
            # Try to get context from surrounding text
            context = get_field_context(pdf_path, page_num, rect) if rect else ""
            
            field_analysis[field_name] = {
                'type': field_properties.get('/FT', 'Unknown'),  # Field Type
                'value': field_properties.get('/V', ''),         # Current Value
                'default_value': field_properties.get('/DV', ''), # Default Value
                'flags': field_properties.get('/Ff', 0),         # Field Flags
                'page_number': page_num,
                'rect': rect,                                    # Field Rectangle
                'required': bool(field_properties.get('/Ff', 0) & 1),  # Required flag
                'read_only': bool(field_properties.get('/Ff', 0) & 2), # Read-only flag
                'label': field_properties.get('/T', ''),         # Field Label
                'tooltip': field_properties.get('/TU', ''),      # Tooltip
                'alternate_name': field_properties.get('/TM', ''), # Alternate Name
                'context': context,                              # Surrounding text
            }
            
        return field_analysis
        
    except Exception as e:
        print(f"Error analyzing PDF: {str(e)}")
        return {}

def print_analysis(analysis: Dict[str, Any]):
    """Prints the analysis in a readable format"""
    if not analysis:
        return
        
    print("\nPDF Form Field Analysis:")
    print("=" * 50)
    
    for field_name, details in analysis.items():
        print(f"\nField: {field_name}")
        print("-" * 30)
        for key, value in details.items():
            if value:  # Only print non-empty values
                if key == 'rect' and len(value) == 4:
                    print(f"{key}: ({value[0]:.1f}, {value[1]:.1f}) to ({value[2]:.1f}, {value[3]:.1f})")
                else:
                    print(f"{key}: {value}")

def save_analysis(analysis: Dict[str, Any], output_path: str):
    """Saves the analysis to a JSON file"""
    with open(output_path, 'w') as f:
        json.dump(analysis, f, indent=2)

def main():
    if len(sys.argv) < 2:
        print("Usage: python pdf_analyzer.py <pdf_path> [output_json_path]")
        return
        
    pdf_path = sys.argv[1]
    output_path = sys.argv[2] if len(sys.argv) > 2 else f"{pdf_path}_analysis.json"
    
    print(f"Analyzing PDF: {pdf_path}")
    analysis = analyze_pdf_form(pdf_path)
    
    if analysis:
        print_analysis(analysis)
        save_analysis(analysis, output_path)
        print(f"\nAnalysis saved to: {output_path}")
    else:
        print("No analysis generated.")

if __name__ == "__main__":
    main() 