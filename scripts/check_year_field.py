import json

# Load both mapping files
with open('audit1_1295_p_mapped_mapping.json', 'r') as f:
    june_mapping = json.load(f)

with open('audit2_1295_p_mapped_mapping.json', 'r') as f:
    december_mapping = json.load(f)

# December Text3 position (year field)
dec_text3_pos = december_mapping['Text3']['position']
print('Dec Text3 position:', dec_text3_pos)

# Look for June field near this position
print('Looking for June field near position x=507, y=726')
for field, info in june_mapping.items():
    if 'position' in info:
        pos = info['position']
        if abs(pos['x'] - 507) < 10 and abs(pos['y'] - 726) < 10:
            print(f'{field}: {pos}') 