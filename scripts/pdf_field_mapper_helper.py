import json
from typing import Dict, List, Tuple
import re

def analyze_nearby_text(nearby_text: List[str]) -> Dict[str, float]:
    """
    Analyze nearby text to determine the likely purpose of a field.
    Returns a dictionary of possible purposes with confidence scores.
    """
    purposes = {
        'date': ['day', 'month', 'year', 'date'],
        'council_info': ['council', 'number', 'location', 'state'],
        'financial': ['cash', 'balance', 'amount', 'total', 'assets', 'liabilities', '$', 'funds'],
        'signature': ['signature', 'signed', 'trustee', 'grand knight'],
        'misc': ['misc', 'other', 'additional']
    }
    
    scores = {purpose: 0.0 for purpose in purposes}
    
    # Convert nearby text to lowercase for matching
    text = ' '.join(nearby_text).lower()
    
    # Calculate scores based on keyword matches
    for purpose, keywords in purposes.items():
        for keyword in keywords:
            if keyword.lower() in text:
                scores[purpose] += 1.0
    
    # Normalize scores
    max_score = max(scores.values()) if scores.values() else 1.0
    if max_score > 0:
        scores = {k: v/max_score for k, v in scores.items()}
    
    return scores

def map_field_purposes(analysis_path: str, mapping_path: str):
    """
    Map fields to their likely purposes based on nearby text.
    """
    print(f"Reading analysis from: {analysis_path}")
    print(f"Reading mapping from: {mapping_path}")
    
    # Load analysis and mapping
    with open(analysis_path, 'r') as f:
        analysis = json.load(f)
    with open(mapping_path, 'r') as f:
        mapping = json.load(f)
    
    field_purposes = {}
    
    # Process each field
    for field_name, field_info in analysis.items():
        if 'nearby_text' not in field_info:
            continue
        
        # Get scores for possible purposes
        scores = analyze_nearby_text(field_info['nearby_text'])
        
        # Get the most likely purpose
        max_score = max(scores.values())
        likely_purposes = [p for p, s in scores.items() if s == max_score]
        
        # Build field info
        field_purposes[field_name] = {
            'type': field_info['type'],
            'position': field_info['position'],
            'likely_purposes': likely_purposes,
            'purpose_scores': scores,
            'nearby_text': field_info['nearby_text']
        }
        
        # Print field information
        print(f"\nField: {field_name}")
        print("-" * 30)
        print(f"Type: {field_info['type']}")
        print("Likely purposes:")
        for purpose in likely_purposes:
            print(f"  - {purpose} (score: {scores[purpose]:.2f})")
        print("Nearby text:")
        print(f"  {' '.join(field_info['nearby_text'])}")
    
    # Save the results
    output_path = analysis_path.replace('_analysis.json', '_purposes.json')
    with open(output_path, 'w') as f:
        json.dump(field_purposes, f, indent=2)
    print(f"\nField purposes saved to: {output_path}")
    
    return field_purposes

if __name__ == "__main__":
    analysis_file = "audit2_1295_p_analysis.json"
    mapping_file = "audit2_1295_p_mapped_mapping.json"
    map_field_purposes(analysis_file, mapping_file) 