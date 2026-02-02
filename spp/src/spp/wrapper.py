import os
import matlab.engine

class SPPMatlabProcessor:
    """
    A persistent MATLAB engine wrapper to handle batch processing efficiently.
    It starts the MATLAB engine once and reuses it for multiple files.
    """
    def __init__(self, matlab_folder_path):
        self.matlab_folder_path = matlab_folder_path
        self.eng = None

    def __enter__(self):
        print("Starting MATLAB Engine (this may take a few seconds)...")
        self.eng = matlab.engine.start_matlab()
        
        # 1. Setup Paths (Once per session)
        abs_script_path = os.path.abspath(self.matlab_folder_path)
        self.eng.addpath(abs_script_path, nargout=0)
        
        # 2. Optimization: Disable plot windows to save resources/focus
        self.eng.eval("set(0, 'DefaultFigureVisible', 'off');", nargout=0)
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.eng:
            self.eng.quit()
            print("MATLAB Engine stopped.")

    def process_file(self, data_filename):
        """
        Runs the analysis on a single file using the persistent engine.
        """
        try:
            # Prepare Arguments: Ensure absolute path and remove extension
            abs_path = os.path.abspath(data_filename)
            fname_no_ext = os.path.splitext(abs_path)[0]
            
            print(f"Running MATLAB analysis on: {os.path.basename(fname_no_ext)}")

            # Call the MATLAB function
            # nargout=0 is required for functions that don't return Python-compatible data
            self.eng.run_spp_analysis(fname_no_ext, nargout=0)
            
        except matlab.engine.MatlabExecutionError as e:
            print(f"MATLAB Error on {data_filename}:\n{e}")
        except Exception as e:
            print(f"Python Error on {data_filename}: {e}")