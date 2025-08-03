import json

# Load June mapping
with open('audit1_1295_p_mapped_mapping.json', 'r') as f:
    june_mapping = json.load(f)

print('June fields with x > 500:')
for field, info in june_mapping.items():
    if 'position' in info and info['position']['x'] > 500:
        print(f'{field}: {info["position"]}') 