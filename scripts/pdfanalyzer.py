from PyPDF2 import PdfReader

# Update this line with your PDF filename
pdf = PdfReader("audit2_1295_p.pdf")
fields = pdf.get_fields()

if fields:
    print("Form fields found:")
    for field_name, field_properties in fields.items():
        print(f"Field: {field_name}")
else:
    print("No form fields found in this PDF or the PDF is not a fillable form.")