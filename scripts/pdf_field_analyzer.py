import pdfplumber
import json
from typing import Dict, List, Tuple
import re

def get_text_near_position(page, x: float, y: float, width: float, height: float, margin: float = 50) -> List[str]:
    """
    Extract text near a given position on the page.
    """
    # Define the search area
    search_box = (
        x - margin,  # left
        y - margin,  # bottom
        x + width + margin,  # right
        y + height + margin   # top
    )
    
    # Extract words in the search area
    words = page.extract_words(
        x_tolerance=3,
        y_tolerance=3,
        keep_blank_chars=False,
        use_text_flow=True
    )
    
    # Filter words within the search area
    nearby_words = []
    for word in words:
        word_box = (word['x0'], word['bottom'], word['x1'], word['top'])
        if (word_box[0] < search_box[2] and word_box[2] > search_box[0] and
            word_box[1] < search_box[3] and word_box[3] > search_box[1]):
            nearby_words.append(word['text'])
    
    return nearby_words

def analyze_pdf_fields(input_path: str, mapping_path: str):
    """
    Analyzes text around form fields to determine their purpose.
    """
    print(f"Analyzing PDF: {input_path}")
    
    # Load field mapping
    with open(mapping_path, 'r') as f:
        field_mapping = json.load(f)
    
    field_analysis = {}
    
    with pdfplumber.open(input_path) as pdf:
        for page_num, page in enumerate(pdf.pages):
            print(f"\nAnalyzing page {page_num + 1}")
            
            # Process each field
            for field_name, field_info in field_mapping.items():
                if 'position' not in field_info:
                    continue
                    
                pos = field_info['position']
                
                # Get text near the field
                nearby_text = get_text_near_position(
                    page,
                    pos['x'],
                    pos['y'],
                    pos['width'],
                    pos['height']
                )
                
                # Store analysis
                field_analysis[field_name] = {
                    'type': field_info['type'],
                    'position': field_info['position'],
                    'nearby_text': nearby_text
                }
    
    # Save the analysis
    analysis_path = input_path.replace('.pdf', '_analysis.json')
    with open(analysis_path, 'w') as f:
        json.dump(field_analysis, f, indent=2)
    print(f"\nField analysis saved to: {analysis_path}")
    
    return field_analysis

if __name__ == "__main__":
    input_pdf = "audit2_1295_p.pdf"
    mapping_path = "audit2_1295_p_mapped_mapping.json"
    analyze_pdf_fields(input_pdf, mapping_path) 