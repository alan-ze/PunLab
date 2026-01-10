import os
import sys

import pandas as pd


def extract_columns_to_csv(file_path):
    workbook = pd.ExcelFile(file_path)

    for sheet_name in workbook.sheet_names:
        sheet_df = workbook.parse(sheet_name, header=1, skiprows=[2])

        required_columns = ["Step time", "Strain (step)", "Shear rate", "Stress (step)"]

        if all(column in sheet_df.columns for column in required_columns):
            extracted_data = sheet_df[required_columns]

            workbook_name = os.path.splitext(os.path.basename(file_path))[0]
            output_filename = f"{workbook_name}_{sheet_name}.csv"

            extracted_data.to_csv(output_filename, index=False, header=False)
            print(f"Data from sheet '{sheet_name}' saved to '{output_filename}'")
        else:
            print(
                f"Sheet '{sheet_name}' in '{file_path}' does not contain all required columns."
            )


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <excel_file>")
        sys.exit(1)

    extract_columns_to_csv(sys.argv[1])
