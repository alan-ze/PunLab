import pandas as pd
import os
import sys

def combine_excel_sheets():
    print("--- Excel Sheet Combiner ---")
    
    # 1. Get input files
    file_input = input("Enter the Excel filenames to combine (separated by commas): ")
    # Clean up input: split by comma, strip whitespace, remove empty strings
    input_files = [f.strip() for f in file_input.split(',') if f.strip()]
    
    if not input_files:
        print("No files provided. Exiting.")
        return

    # Verify files exist before processing
    for f in input_files:
        if not os.path.exists(f):
            print(f"Error: File '{f}' not found.")
            return

    # 2. Get output filename
    output_name = input("Enter the name for the new Excel file (e.g., combined.xlsx): ").strip()
    if not output_name.lower().endswith('.xlsx'):
        output_name += '.xlsx'

    print(f"\nProcessing into '{output_name}'...")

    try:
        # Create a writer object using 'openpyxl' engine
        with pd.ExcelWriter(output_name, engine='openpyxl') as writer:
            existing_sheet_names = set()

            for file_path in input_files:
                print(f"  Reading {file_path}...")
                
                # Load the excel file (None loads all sheets)
                xls = pd.read_excel(file_path, sheet_name=None)
                
                for sheet_name, df in xls.items():
                    # Handle duplicate sheet names
                    final_sheet_name = sheet_name
                    counter = 1
                    
                    while final_sheet_name in existing_sheet_names:
                        final_sheet_name = f"{sheet_name}_{counter}"
                        counter += 1
                    
                    # Track the new name
                    existing_sheet_names.add(final_sheet_name)
                    
                    # Write the sheet to the new file
                    df.to_excel(writer, sheet_name=final_sheet_name, index=False)
                    print(f"    -> Added sheet: '{sheet_name}' as '{final_sheet_name}'")

        print(f"\nSuccess! All sheets combined into: {os.path.abspath(output_name)}")

    except Exception as e:
        print(f"\nAn error occurred: {e}")

if __name__ == "__main__":
    combine_excel_sheets()