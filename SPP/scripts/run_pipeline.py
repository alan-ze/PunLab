import re
import sys
from pathlib import Path

# Import the new class instead of the old function
from spp.preprocess import extract_columns_to_csv
from spp.wrapper import SPPMatlabProcessor

def main(input_folder, output_folder, matlab_folder_path):
    input_folder = Path(input_folder)
    output_folder = Path(output_folder)
    output_folder.mkdir(parents=True, exist_ok=True)

    pattern = re.compile(r"TJC2_.*\.xls(x)?$")
    files = list(input_folder.glob("*.xls*"))
    relevant_files = [f for f in files if pattern.match(f.name)]

    # Initialize MATLAB engine ONCE before the loop
    with SPPMatlabProcessor(matlab_folder_path) as processor:
        for file_path in relevant_files:
            try:
                print(f"Working on {file_path.name}...")
                
                # 1. Extract CSVs from Excel
                excel_data_files = extract_columns_to_csv(
                    str(file_path), str(output_folder)
                )
                
                # 2. Process extracted CSVs in MATLAB
                for data_file in excel_data_files:
                    print(f"  Processing extracted data file: {data_file}")
                    processor.process_file(data_file)
                    
            except Exception as e:
                print(f"Error processing {file_path.name}: {e}")
    ## pixi run python scripts\run_pipeline.py "C:\Users\alanh\PunLab\spp\experiments\Pigs_NegCon" "C:\Users\alanh\PunLab\spp\experiments\Pigs_NegCon" "C:\Users\alanh\PunLab\spp\matlab_code"



def start_from_csv(input_folder, matlab_folder_path):
    input_folder = Path(input_folder)
    pattern = re.compile(r".*_Sine Strain - \d+\.csv$")
    csv_files = list(input_folder.glob("*.csv"))
    relevant_csv_files = [f for f in csv_files if pattern.match(f.name)]

    # Initialize MATLAB engine ONCE before the loop
    with SPPMatlabProcessor(matlab_folder_path) as processor:
        for file_path in relevant_csv_files:
            try:
                print(f"Processing CSV file: {file_path.name}")
                # Pass the full path; the wrapper class handles extension stripping
                processor.process_file(str(file_path))
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