import os
from unittest.mock import MagicMock, patch

import pytest

from spp.wrapper import run_matlab_wrapper

# ==========================================
# 1. MOCKED UNIT TESTS (Fast, No License Needed)
# ==========================================


@patch("matlab.engine.start_matlab")
def test_wrapper_calls_matlab_correctly(mock_start_matlab):
    """
    Verifies that the python wrapper calculates paths correctly and
    calls the MATLAB function with the right arguments.
    """
    # --- Setup ---
    # Create a mock engine object that start_matlab returns
    mock_eng = MagicMock()
    mock_start_matlab.return_value = mock_eng

    # Fake inputs
    fake_data_path = "/path/to/data/Test_Experiment.csv"
    fake_matlab_dir = "./matlab_code"

    # --- Action ---
    run_matlab_wrapper(fake_data_path, fake_matlab_dir)

    # --- Assertions ---

    # 1. Did the engine start?
    mock_start_matlab.assert_called_once()

    # 2. Did we add the MATLAB script directory to the path?
    # We check if addpath was called. We use os.path.abspath to match the wrapper's logic.
    expected_path = os.path.abspath(fake_matlab_dir)
    mock_eng.addpath.assert_called_with(expected_path, nargout=0)

    # 3. Did we call the specific analysis function?
    # We expect the absolute filepath without extension (wrapper now passes full path)
    expected_fname = os.path.splitext(os.path.abspath(fake_data_path))[0]
    mock_eng.run_spp_analysis.assert_called_with(expected_fname, nargout=0)

    # 4. Did the engine quit properly?
    mock_eng.quit.assert_called_once()


@patch("matlab.engine.start_matlab")
def test_wrapper_handles_matlab_error(mock_start_matlab):
    """
    Verifies that the wrapper gracefully handles a MATLAB execution error.
    """
    mock_eng = MagicMock()
    mock_start_matlab.return_value = mock_eng

    # Simulate an error when the function is called
    # We have to import the error class to mock it, or just use a generic Exception for simplicity
    # if you want to be specific, you'd need to mock matlab.engine.MatlabExecutionError
    mock_eng.run_spp_analysis.side_effect = Exception("Simulated MATLAB Crash")

    # Run the wrapper (it should catch the error and print, not crash)
    try:
        run_matlab_wrapper("dummy.csv", "dummy_dir")
    except Exception:
        pytest.fail(
            "The wrapper should have caught the exception but raised it instead."
        )

    # Ensure quit is still called even after an error (cleanup check)
    mock_eng.quit.assert_called_once()


# # ==========================================
# # 2. INTEGRATION TESTS (Slow, Requires License)
# # ==========================================


# @pytest.mark.integration
# def test_real_matlab_execution():
#     """
#     This test ACTUALLY runs MATLAB.
#     It requires the environment to be set up correctly and a valid license.
#     """
#     # Define paths to real files for the test
#     # You might want to create a tiny dummy .m file and dummy .csv for this test
#     # to avoid running your heavy scientific calculation.

#     real_data = "tests/fixtures/dummy_data.csv"  # Create this small file
#     real_matlab_dir = "matlab_code"  # Ensure this exists

#     # Skip if files don't exist (prevents failing on machines without data)
#     if not os.path.exists(real_matlab_dir):
#         pytest.skip("MATLAB code directory not found")

#     # Example assertion (this depends on what your wrapper returns/does)
#     # Since your wrapper prints to stdout, we might just check it runs without error
#     try:
#         # Pass a non-existent file to trigger the file-not-found check
#         # inside your MATLAB script, which is safer than running a full calc.
#         run_matlab_wrapper("non_existent_file.csv", real_matlab_dir)
#     except Exception as e:
#         pytest.fail(f"Integration test failed with error: {e}")

# import pytest
# import os
# from src.wrapper import run_matlab_wrapper
# from unittest.mock import patch, MagicMock

# # --- 1. Define Fixtures (The Data Providers) ---

# @pytest.fixture
# def mock_data_file(tmp_path):
#     """Creates a temporary dummy CSV file."""
#     # tmp_path is a pathlib object provided by pytest
#     d = tmp_path / "data"
#     d.mkdir()
#     p = d / "test_data.csv"
#     p.write_text("Time,Strain,Rate,Stress\n1,2,3,4") # Create actual file content
#     return str(p) # Return the path as a string

# @pytest.fixture
# def mock_matlab_folder(tmp_path):
#     """Creates a temporary dummy MATLAB folder."""
#     d = tmp_path / "matlab_code"
#     d.mkdir()
#     # Create a dummy .m file just in case
#     p = d / "run_spp_analysis.m"
#     p.write_text("function run_spp_analysis(f); end")
#     return str(d)

# # --- 2. The Test Function ---

# @patch('matlab.engine.start_matlab')
# def test_wrapper_with_fixtures(mock_start_matlab, mock_data_file, mock_matlab_folder):
#     """
#     Notice how 'mock_data_file' and 'mock_matlab_folder' are passed
#     as arguments to this test function? Pytest sees the names match
#     the fixtures above and automatically injects the return values.
#     """

#     # Setup the mock engine
#     mock_eng = MagicMock()
#     mock_start_matlab.return_value = mock_eng

#     # CALL THE WRAPPER
#     # We pass the paths that pytest generated for us
#     run_matlab_wrapper(mock_data_file, mock_matlab_folder)

#     # ASSERT
#     # Verify the wrapper stripped the extension correctly
#     # "test_data.csv" -> "test_data"
#     mock_eng.run_spp_analysis.assert_called_with("test_data", nargout=0)
