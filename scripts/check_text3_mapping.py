import json

# Load both mapping files
with open('audit1_1295_p_mapped_mapping.json', 'r') as f:
    june_mapping = json.load(f)

with open('audit2_1295_p_mapped_mapping.json', 'r') as f:
    december_mapping = json.load(f)

# December Text3 position (year field)
dec_text3_pos = december_mapping['Text3']['position']
print('Dec Text3 position:', dec_text3_pos)

# Look for any June field that might correspond to Text3
print('\nLooking for June field that might correspond to Dec Text3 (year field):')
for field, info in june_mapping.items():
    if 'position' in info:
        pos = info['position']
        # Check if it's in a similar area (top right of the form)
        if pos['x'] > 500 and pos['y'] > 700:
            print(f'{field}: {pos}') 