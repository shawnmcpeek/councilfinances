import csv
import json
import os

# Convert CSV to JSON for Firestore import
csv_file = "2025 Council 15857 Finances - Transactions.csv"
json_file = "financial_entries.json"

with open(csv_file, "r") as f:
    reader = csv.reader(f)
    # Read header row and remove leading empty field
    header_row = next(reader)
    header = [h.strip() for h in header_row[1:]]
    print("Found header:", header)

    row_count = 0
    entries = []
    for row in reader:
        row_count += 1
        # Skip empty rows
        if not row or len(row) < 2:
            continue
        # Remove leading empty field
        row = row[1:]
        if len(row) < len(header):
            print(f"Skipping row {row_count}: Not enough fields")
            continue
        data = dict(zip(header, row))
        # Skip rows missing required fields
        if not all(data.get(field) for field in ['Category', 'Date', 'Amount']):
            print(f"Skipping row {row_count}: Missing required fields")
            continue
        # Clean up the data
        if 'Amount' in data:
            data['Amount'] = data['Amount'].replace('$', '').replace(',', '')
        entries.append(data)

with open(json_file, "w") as f:
    json.dump(entries, f, indent=2)

print("\nConversion complete:")
print(f"Total rows processed: {row_count}")
print(f"Total entries converted: {len(entries)}")
print(f"Output written to: {json_file}")

if entries:
    print("\nExample entry:")
    print(json.dumps(entries[0], indent=2)) 