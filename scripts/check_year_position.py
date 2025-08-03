import json

# Load June mapping
with open('audit1_1295_p_mapped_mapping.json', 'r') as f:
    june_mapping = json.load(f)

print('June fields with y > 600 (header area):')
for field, info in june_mapping.items():
    if 'position' in info and info['position']['y'] > 600:
        print(f'{field}: {info["position"]}')

print('\nCurrent year field (Text345):', june_mapping['Text345']['position'])
print('Current membership field (Text416):', june_mapping['Text416']['position']) 