import os

import pandas as pd


def extract_columns_to_csv(file_path, output_dir="."):
    """
    Extracts specific columns from each sheet of an Excel file and saves them as CSV files.

    Args:
        file_path (str): Path to the Excel file.
        output_dir (str, optional): Path to the folder for the output files. Defaults to ".".

    Returns:
        created_files (list[str]): List of created CSV filenames.
    """
    workbook = pd.ExcelFile(file_path)
    created_files = []  # Track files

    for sheet_name in workbook.sheet_names:
        sheet_df = workbook.parse(sheet_name, header=1, skiprows=[2])

        required_columns = ["Step time", "Strain (step)", "Shear rate", "Stress (step)"]

        if all(column in sheet_df.columns for column in required_columns):
            extracted_data = sheet_df[required_columns]

            workbook_name = os.path.splitext(os.path.basename(file_path))[0]
            # Output to new output_dir parameter
            output_filename = os.path.join(
                output_dir, f"{workbook_name}_{sheet_name}.csv"
            )

            extracted_data.to_csv(output_filename, index=False, header=False)
            created_files.append(output_filename)
        else:
            print(
                f"Sheet '{sheet_name}' in '{file_path}' does not contain all required columns."
            )
    return created_files  # Replace the old print statement
