import glob
import os
import re  # 1. Import regex module
import sys

import pandas as pd


def convert_txt_to_csv(file_path):
    """
    Converts a single .txt file to the specified .csv format.
    """
    try:
        # 1. Parse Header Information (Frequency)
        frequency = None
        header_rows_to_skip = 0

        with open(file_path) as f:
            lines = f.readlines()
            for i, line in enumerate(lines):
                if "Frequency:" in line:
                    parts = line.strip().split()
                    for part in parts:
                        try:
                            frequency = float(part)
                            break
                        except ValueError:
                            continue

                if line.strip().startswith("Time") and "Strain" in line:
                    header_rows_to_skip = i
                    break

        if frequency is None:
            print(f"Warning: Could not find 'Frequency:' in {file_path}. Setting to 0.")
            frequency = 0.0

        # 2. Read the Data Table
        df = pd.read_csv(file_path, sep="\t", skiprows=header_rows_to_skip)

        if df.shape[1] < 2:
            df = pd.read_csv(file_path, sep=r"\s+", skiprows=header_rows_to_skip)

        # 3. Clean up the DataFrame
        try:
            pd.to_numeric(df.iloc[0, 0])
        except ValueError:
            df = df.iloc[1:].reset_index(drop=True)

        cols_to_convert = ["Time", "Stress", "Strain", "Rate"]
        for col in cols_to_convert:
            if col in df.columns:
                df[col] = pd.to_numeric(df[col], errors="coerce")

        # 4. Calculate Derived Values
        max_strain = df["Strain"].max()

        # 5. Create New DataFrame
        output_df = pd.DataFrame()

        if "Time" in df.columns:
            output_df["Step time"] = df["Time"]
        if "Stress" in df.columns:
            output_df["Stress"] = df["Stress"]
        if "Strain" in df.columns:
            output_df["Strain"] = df["Strain"]
        if "Rate" in df.columns:
            output_df["Shear rate"] = df["Rate"]

        output_df["Angular frequency"] = frequency
        output_df["Oscillation strain"] = max_strain * 100  # Convert to percentage

        # 6. Save to CSV
        directory = os.path.dirname(file_path)
        base_name = os.path.splitext(os.path.basename(file_path))[0]
        output_filename = os.path.join(directory, f"{base_name}.csv")

        output_df.to_csv(output_filename, index=False)
        print(f"Successfully converted: {base_name}.txt -> {output_filename}")

    except Exception as e:
        print(f"Error processing {file_path}: {e}")


def main():
    # 1. Collect arguments (or default to current directory)
    if len(sys.argv) > 1:
        paths_to_check = sys.argv[1:]
    else:
        print("No file arguments provided. Scanning current directory...")
        paths_to_check = ["."]

    files_to_process = []

    # 2. Use glob to find files
    for path in paths_to_check:
        # Case A: The path is a Folder (e.g. "experiments")
        # We automatically look for *FOURIER.txt inside it
        if os.path.isdir(path):
            search_pattern = os.path.join(path, "*FOURIER.txt")
            found_files = glob.glob(search_pattern)
            files_to_process.extend(found_files)
        
        # Case B: The path is a File or a Glob Pattern (e.g. "data/*.txt")
        else:
            # glob.glob handles specific files OR wildcard patterns
            matches = glob.glob(path)
            # Filter to ensure they actully match the naming convention
            # (Useful if the user accidentally passed "all_files.txt")
            valid_matches = [f for f in matches if f.lower().endswith("fourier.txt")]
            files_to_process.extend(valid_matches)

    # 3. Process found files
    if not files_to_process:
        print(f"No files ending in 'FOURIER.txt' found in: {paths_to_check}")
        return

    print(f"Found {len(files_to_process)} matching file(s). Processing...")

    for txt_file in files_to_process:
        convert_txt_to_csv(txt_file)

    print("All done.")


if __name__ == "__main__":
    main()
