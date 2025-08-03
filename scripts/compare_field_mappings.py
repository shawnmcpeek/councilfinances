import json

def compare_field_mappings():
    """Compare field positions between June and December templates"""
    
    # Load both mapping files
    with open('audit1_1295_p_mapped_mapping.json', 'r') as f:
        june_mapping = json.load(f)
    
    with open('audit2_1295_p_mapped_mapping.json', 'r') as f:
        december_mapping = json.load(f)
    
    print("Comparing field positions...")
    print(f"June template has {len(june_mapping)} fields")
    print(f"December template has {len(december_mapping)} fields")
    print()
    
    # Find fields with similar positions (within 5 points)
    matches = []
    
    for june_field, june_info in june_mapping.items():
        if 'position' not in june_info:
            continue
            
        june_x = june_info['position']['x']
        june_y = june_info['position']['y']
        
        for december_field, december_info in december_mapping.items():
            if 'position' not in december_info:
                continue
                
            december_x = december_info['position']['x']
            december_y = december_info['position']['y']
            
            # Check if positions are similar (within 5 points)
            if abs(june_x - december_x) < 5 and abs(june_y - december_y) < 5:
                matches.append({
                    'june_field': june_field,
                    'december_field': december_field,
                    'june_pos': (june_x, june_y),
                    'december_pos': (december_x, december_y),
                    'distance': ((june_x - december_x)**2 + (june_y - december_y)**2)**0.5
                })
    
    # Sort by distance (closest matches first)
    matches.sort(key=lambda x: x['distance'])
    
    print("Matching fields (position-based):")
    print("-" * 60)
    for match in matches[:20]:  # Show top 20 matches
        print(f"{match['june_field']:8} -> {match['december_field']:8} | "
              f"June: ({match['june_pos'][0]:.1f}, {match['june_pos'][1]:.1f}) | "
              f"Dec: ({match['december_pos'][0]:.1f}, {match['december_pos'][1]:.1f}) | "
              f"Distance: {match['distance']:.1f}")
    
    print()
    print("Creating mapping for Edge Function...")
    print("-" * 60)
    
    # Create the mapping for the Edge Function
    field_mapping = {}
    for match in matches:
        june_field = match['june_field']
        december_field = match['december_field']
        field_mapping[june_field] = december_field
    
    # Print the mapping in a format we can use
    print("June -> December field mapping:")
    for june_field, december_field in sorted(field_mapping.items()):
        print(f"'{june_field}': '{december_field}',")
    
    return field_mapping

if __name__ == "__main__":
    compare_field_mappings() 