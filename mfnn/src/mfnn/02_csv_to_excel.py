import glob
import os
import sys

import pandas as pd


def get_target_directory():
    """
    Determines the target directory based on command line arguments
    or user input.
    """
    # Check if path was passed as a command line argument
    if len(sys.argv) > 1:
        # Join arguments in case path has spaces and wasn't quoted
        path = " ".join(sys.argv[1:])
    else:
        # Ask user for input if no argument provided
        path = input(
            "Please paste the full directory path containing the CSV files:\n> "
        )

    # Clean up quotes that might be included when copying paths (Windows specific)
    path = path.strip().strip('"').strip("'")

    return path


def process_directory(target_dir):
    # 1. Validate directory
    if not os.path.isdir(target_dir):
        print(f"\n[Error] The directory does not exist: {target_dir}")
        return

    print(f"\nScanning directory: {target_dir}")

    # 2. Find all .csv files in the specific directory
    search_pattern = os.path.join(target_dir, "*FOURIER.csv")
    csv_files = glob.glob(search_pattern)

    if not csv_files:
        print("No CSV files found in that directory.")
        return

    # 3. Group files by the first 9 characters of their FILENAME
    file_groups = {}
    for file_path in csv_files:
        filename = os.path.basename(file_path)
        group_id = filename[:9]

        if group_id not in file_groups:
            file_groups[group_id] = []
        file_groups[group_id].append(file_path)

    print(f"Found {len(file_groups)} groups of files.")

    # 4. Process each group
    for group_id, files in file_groups.items():
        output_filename = os.path.join(target_dir, f"{group_id}.xlsx")
        print(
            f"Processing group '{group_id}' -> Creating '{os.path.basename(output_filename)}'..."
        )

        # --- NEW LOGIC: Read all files first, then sort, then write ---

        # List to hold dictionaries of {filename, dataframe, max_strain, max_freq}
        group_data_list = []

        # 4a. Read and Collect Data
        for csv_file in files:
            try:
                df = pd.read_csv(csv_file)

                # Verify columns
                if (
                    "Angular frequency" not in df.columns
                    or "Oscillation strain" not in df.columns
                ):
                    print(f"  [Skipped] {os.path.basename(csv_file)}: Missing columns.")
                    continue

                # Find largest values
                max_ang_freq = df["Angular frequency"].max()
                max_osc_strain = df["Oscillation strain"].max()

                # Append to list
                group_data_list.append(
                    {
                        "filename": os.path.basename(csv_file),
                        "dataframe": df,
                        "max_ang_freq": max_ang_freq,
                        "max_osc_strain": max_osc_strain,
                    }
                )

            except Exception as e:
                print(f"  [Error] reading {os.path.basename(csv_file)}: {e}")

        # 4b. Sort the list by Oscillation Strain (lowest to highest)
        if not group_data_list:
            print(f"  [Skipped] No valid CSV data found for group {group_id}")
            continue

        group_data_list.sort(key=lambda x: x["max_osc_strain"])

        # 4c. Write sorted data to Excel
        try:
            with pd.ExcelWriter(output_filename, engine="openpyxl") as writer:
                used_sheet_names = set()

                for data_item in group_data_list:
                    df = data_item["dataframe"]
                    max_ang_freq = data_item["max_ang_freq"]
                    max_osc_strain = data_item["max_osc_strain"]
                    original_filename = data_item["filename"]

                    # Create Sheet Name
                    sheet_name = f"{max_ang_freq}rad - {max_osc_strain}"

                    # Sanitize Sheet Name
                    invalid_chars = [":", "\\", "/", "?", "*", "[", "]"]
                    for char in invalid_chars:
                        sheet_name = sheet_name.replace(char, "_")

                    # Excel Limit: 31 characters
                    if len(sheet_name) > 31:
                        sheet_name = sheet_name[:31]

                    # Handle Duplicates
                    base_sheet_name = sheet_name
                    counter = 1
                    while sheet_name in used_sheet_names:
                        suffix = f"_{counter}"
                        allowed_len = 31 - len(suffix)
                        sheet_name = f"{base_sheet_name[:allowed_len]}{suffix}"
                        counter += 1

                    used_sheet_names.add(sheet_name)

                    # Write to Excel
                    df.to_excel(writer, sheet_name=sheet_name, index=False)
                    print(f"  [Added] {original_filename} -> Sheet: {sheet_name}")

        except Exception as e:
            print(f"  [Error] Failed to write Excel file {output_filename}: {e}")

    print("\nProcessing complete.")


if __name__ == "__main__":
    # If arguments are provided, treat each as a separate directory
    if len(sys.argv) > 1:
        # We skip the first arg (the script name) and loop the rest
        for folder in sys.argv[1:]:
            process_directory(folder.strip().strip('"').strip("'"))
    else:
        # Fallback to the interactive input if no args provided
        target_directory = get_target_directory()
        process_directory(target_directory)
