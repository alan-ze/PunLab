import os

import matlab.engine


def run_matlab_wrapper(data_filename, matlab_folder_path):
    """
    Wrapper to run the SPP MATLAB analysis.
    """
    print("Starting MATLAB Engine...")
    # Start MATLAB asynchronously
    eng = matlab.engine.start_matlab()

    try:
        # 1. Setup Paths
        # We must tell MATLAB where the .m files are
        abs_script_path = os.path.abspath(matlab_folder_path)
        eng.addpath(abs_script_path, nargout=0)

        # 2. Prepare Arguments
        # Use absolute path without extension so MATLAB can locate the file
        fname_no_ext = os.path.splitext(os.path.abspath(data_filename))[0]

        print(f"Running analysis on: {fname_no_ext}")

        # 3. Call the MATLAB function
        # nargout=0 is REQUIRED because your MATLAB function returns nothing.
        # If you omit this, Python will hang waiting for a return value.
        eng.run_spp_analysis(fname_no_ext, nargout=0)

        print("MATLAB analysis completed successfully.")

    except matlab.engine.MatlabExecutionError as e:
        print(f"MATLAB Error occurred:\n{e}")
    except Exception as e:
        print(f"Python Error: {e}")
    finally:
        # 4. Cleanup
        eng.quit()
        print("MATLAB Engine stopped.")


if __name__ == "__main__":
    # Configuration
    # Adjust these paths relative to where you run the script from
    MATLAB_SRC_DIR = "./matlab_code"
    DATA_FILE = "TJC2_36C4_Sine Strain - 2.csv"  # Example file

    run_matlab_wrapper(DATA_FILE, MATLAB_SRC_DIR)
