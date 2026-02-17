import pandas as pd
import os
import sys

def combine_excel_sheets(input_dir, output_dir, file_name):
    """
    Combines all sheets from all Excel files in input_dir into a single file 
    located in output_dir.
    """

    # 1. Validate Input Directory
    if not os.path.exists(input_dir):
        print(f"Error: Input directory '{input_dir}' does not exist.")
        return

    # 2. Prepare Output Directory and Filename
    # Create output directory if it doesn't exist
    if not os.path.exists(output_dir):
        try:
            os.makedirs(output_dir)
            print(f"Created output directory: {output_dir}")
        except OSError as e:
            print(f"Error creating output directory: {e}")
            return

    # Ensure extension is correct
    if not file_name.lower().endswith('.xlsx'):
        file_name += '.xlsx'
    
    output_path = os.path.join(output_dir, file_name)

    # 3. Get list of Excel files
    # Filter for .xlsx and .xls, ignore temporary files (~$)
    input_files = [
        f for f in os.listdir(input_dir) 
        if f.lower().endswith(('.xlsx', '.xls')) and not f.startswith('~$')
    ]

    if not input_files:
        print(f"No Excel files found in '{input_dir}'. Exiting.")
        return

    print(f"Found {len(input_files)} files. Processing into '{output_path}'...")

    try:
        # Create a writer object
        with pd.ExcelWriter(output_path, engine='openpyxl') as writer:
            existing_sheet_names = set()

            for filename in input_files:
                file_path = os.path.join(input_dir, filename)

                # Skip if we are accidentally reading the file we are currently writing
                if os.path.abspath(file_path) == os.path.abspath(output_path):
                    continue

                print(f"  Reading {filename}...")
                
                try:
                    # Load all sheets
                    xls = pd.read_excel(file_path, sheet_name=None)
                    
                    for sheet_name, df in xls.items():
                        # Handle duplicate sheet names
                        final_sheet_name = sheet_name
                        counter = 1
                        
                        # Identify origin file in sheet name if collision occurs
                        # or simply append number to ensure uniqueness
                        while final_sheet_name in existing_sheet_names:
                            final_sheet_name = f"{sheet_name}_{counter}"
                            counter += 1
                        
                        existing_sheet_names.add(final_sheet_name)
                        
                        # Write the sheet
                        df.to_excel(writer, sheet_name=final_sheet_name, index=False)
                        print(f"    -> Added sheet: '{sheet_name}' as '{final_sheet_name}'")
                
                except Exception as e:
                    print(f"    Warning: Could not read {filename}. Reason: {e}")

        print(f"\nSuccess! File saved at: {os.path.abspath(output_path)}")

    except Exception as e:
        print(f"\nAn error occurred during writing: {e}")

# Example Usage
if __name__ == "__main__":
    # You can hardcode paths here to test:
    # combine_excel_sheets('./data_in', './data_out', 'master_file.xlsx')
    
    # Or use command line arguments: python script.py <in_dir> <out_dir> <filename>
    if len(sys.argv) == 4:
        combine_excel_sheets(sys.argv[1], sys.argv[2], sys.argv[3])
    else:
        print("Usage: python script.py <input_dir> <output_dir> <file_name>")