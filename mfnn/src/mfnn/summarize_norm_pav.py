import glob
import os
import sys
from pathlib import Path

import pandas as pd


def summarize_norm_pav(file_path):
    """
    Searches directory for all .txt files, locates norm. PAV and writes a summary
    """
    try:
        # Find start
        header_rows_to_skip = None

        with open(file_path) as f:
            lines = f.readlines()
            for i, line in enumerate(lines):
                if line.strip().startswith("Time") and "Strain" in line:
                    header_rows_to_skip = i
                    break
        if header_rows_to_skip is None:
            raise ValueError("No hehader")

        # Read data
        df = pd.read_csv(file_path, sep="\t", skiprows=header_rows_to_skip)

        if df.shape[1] < 2:  # fallback
            df = pd.read_csv(file_path, sep=r"\s+", skiprows=header_rows_to_skip)

        # Clean up the DataFrame
        try:
            pd.to_numeric(df.iloc[0, 0])  # Drop first row if no data (units)
        except ValueError:
            df = df.iloc[1:].reset_index(drop=True)

        cols_to_convert = ["Time", "norm. PAV"]
        for col in cols_to_convert:
            if col in df.columns:
                df[col] = pd.to_numeric(df[col], errors="coerce")
            else:
                raise ValueError(f"{col} not in file")

        # Calculate
        file_name = Path(file_path).name
        max_pav = df["norm. PAV"].max()
        min_pav = df["norm. PAV"].min()
        max_pav_time = df.loc[df["norm. PAV"] == max_pav, "Time"].iloc[0]
        min_pav_time = df.loc[df["norm. PAV"] == min_pav, "Time"].iloc[0]

        # Create dataframe
        output_df = pd.DataFrame(
            [
                {
                    "file_name": file_name,
                    "max_pav_time": max_pav_time,
                    "max_pav": max_pav,
                    "min_pav_time": min_pav_time,
                    "min_pav": min_pav,
                }
            ]
        )

        return output_df

    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return pd.DataFrame()


def main():
    # Collect arguments (or default to current directory)
    if len(sys.argv) > 1:
        paths_to_check = sys.argv[1:]
    else:
        print("No file arguments provided. Scanning current directory...")
        paths_to_check = ["."]

    files_to_process = []

    # Use glob to find files
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

    # Process found files
    if not files_to_process:
        print(f"No files ending in 'FOURIER.txt' found in: {paths_to_check}")
        return

    print(f"Found {len(files_to_process)} matching file(s). Processing...")
    results = []

    for txt_file in files_to_process:
        temp_df = summarize_norm_pav(txt_file)
        results.append(temp_df)
    df = pd.concat(results, ignore_index=True)
    df.to_csv("norm_pav_summary.csv", index=False)
    print("All done.")


if __name__ == "__main__":
    main()
