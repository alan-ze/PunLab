import re
import sys
from pathlib import Path

from spp.preprocess import extract_columns_to_csv
from spp.wrapper import run_matlab_wrapper


def main(input_folder, output_folder, matlab_folder_path):
    input_folder = Path(input_folder)
    output_folder = Path(output_folder)
    output_folder.mkdir(parents=True, exist_ok=True)

    pattern = re.compile(r"TJC2_.*\.xls(x)?$")
    files = list(input_folder.glob("*.xls*"))
    relevant_files = [f for f in files if pattern.match(f.name)]

    # 3. Process loop
    for file_path in relevant_files:
        try:
            print(f"Working on {file_path.name}...")
            excel_data_files = extract_columns_to_csv(
                str(file_path), str(output_folder)
            )
            for data_file in excel_data_files:
                print(f"  Processing extracted data file: {data_file}")
                run_matlab_wrapper(data_file, matlab_folder_path)
        except Exception as e:
            print(f"Error processing {file_path.name}: {e}")


def start_from_csv(input_folder, matlab_folder_path):
    input_folder = Path(input_folder)
    pattern = re.compile(r".*_Sine Strain - \d+\.csv$")
    csv_files = list(input_folder.glob("*.csv"))
    relevant_csv_files = [f for f in csv_files if pattern.match(f.name)]

    for file_path in relevant_csv_files:
        try:
            print(f"Processing CSV file: {file_path.name}")
            run_matlab_wrapper(str(file_path.with_suffix('')), matlab_folder_path)
        except Exception as e:
            print(f"Error processing {file_path.name}: {e}")


if __name__ == "__main__":
    # Check if we have enough arguments
    if len(sys.argv) < 3:
        print("Usage: python run_pipeline.py <input_folder> <output_folder> <matlab_folder>")
        print("   OR: python run_pipeline.py --csv <input_folder> <matlab_folder>")
        sys.exit(1)

    # Option to run just the CSV part
    if sys.argv[1] == "--csv":
        # Usage: python run_pipeline.py --csv <input_folder> <matlab_folder>
        start_from_csv(sys.argv[2], sys.argv[3])
    else:
        # Standard usage
        main(sys.argv[1], sys.argv[2], sys.argv[3])

    # pixi run python scripts/run_pipeline.py --csv ./my_input_folder ./my_matlab_path

# if __name__ == "__main__":
#     import argparse

#     parser = argparse.ArgumentParser(description="SPP Pipeline Runner")
#     subparsers = parser.add_subparsers(dest="command", required=True, help="Choose a mode")

#     # Mode 1: Full Pipeline (Excel -> CSV -> Matlab)
#     # Usage: python run_pipeline.py full <input> <output> <matlab>
#     parser_full = subparsers.add_parser("full", help="Run full pipeline from Excel files")
#     parser_full.add_argument("input_folder", help="Folder containing raw Excel files")
#     parser_full.add_argument("output_folder", help="Folder to save extracted CSVs")
#     parser_full.add_argument("matlab_folder", help="Folder containing Matlab scripts")

#     # Mode 2: CSV Only (CSV -> Matlab)
#     # Usage: python run_pipeline.py csv <input> <matlab>
#     parser_csv = subparsers.add_parser("csv", help="Run pipeline starting from existing CSVs")
#     parser_csv.add_argument("input_folder", help="Folder containing CSV files")
#     parser_csv.add_argument("matlab_folder", help="Folder containing Matlab scripts")

#     args = parser.parse_args()

#     if args.command == "full":
#         main(args.input_folder, args.output_folder, args.matlab_folder)
#     elif args.command == "csv":
#         start_from_csv(args.input_folder, args.matlab_folder)
