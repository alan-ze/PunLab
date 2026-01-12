import os
import pytest
from unittest.mock import MagicMock, patch, ANY
from spp.wrapper import SPPMatlabProcessor

# -------------------------------------------------------------------------
# Fixtures
# -------------------------------------------------------------------------

@pytest.fixture
def mock_matlab():
    """
    Mocks the entire matlab.engine module.
    Crucially, we must Mock the Exception class so it can be caught in try/except blocks.
    """
    with patch("spp.wrapper.matlab.engine") as mock_pkg:
        # 1. Define a fake Exception class for the mock to use
        class FakeMatlabExecutionError(Exception):
            pass
        
        # 2. Assign this fake class to the mock package
        mock_pkg.MatlabExecutionError = FakeMatlabExecutionError
        
        # 3. Setup the engine instance that start_matlab() returns
        mock_eng_instance = MagicMock()
        mock_pkg.start_matlab.return_value = mock_eng_instance
        
        yield mock_pkg, mock_eng_instance, FakeMatlabExecutionError

# -------------------------------------------------------------------------
# Unit Tests
# -------------------------------------------------------------------------

def test_context_manager_lifecycle(mock_matlab):
    """
    Verifies that the engine starts on __enter__ and quits on __exit__.
    """
    mock_pkg, mock_eng, _ = mock_matlab
    folder_path = "./matlab_src"
    abs_folder_path = os.path.abspath(folder_path)

    # Act: Use the context manager
    with SPPMatlabProcessor(folder_path) as processor:
        # Assert: Engine started
        mock_pkg.start_matlab.assert_called_once()
        assert processor.eng == mock_eng
        
        # Assert: Path added (using absolute path)
        mock_eng.addpath.assert_called_with(abs_folder_path, nargout=0)
        
        # Assert: Optimization (figures hidden)
        mock_eng.eval.assert_called_with("set(0, 'DefaultFigureVisible', 'off');", nargout=0)

    # Assert: Engine quit on exit
    mock_eng.quit.assert_called_once()


def test_process_file_success(mock_matlab):
    """
    Verifies that process_file correctly formats the filename and calls the engine.
    """
    _, mock_eng, _ = mock_matlab
    processor = SPPMatlabProcessor("./dummy_path")
    
    # Manually attach the mock engine (simulating being inside the 'with' block)
    processor.eng = mock_eng
    
    input_file = "data/raw/experiment_data.csv"
    expected_arg = os.path.splitext(os.path.abspath(input_file))[0]

    # Act
    processor.process_file(input_file)

    # Assert
    mock_eng.run_spp_analysis.assert_called_once()
    
    # Check arguments: (filename_no_ext, nargout=0)
    args, kwargs = mock_eng.run_spp_analysis.call_args
    assert args[0] == expected_arg
    assert kwargs == {'nargout': 0}


def test_process_file_catches_matlab_error(mock_matlab, capsys):
    """
    Verifies that if MATLAB throws a specific execution error, the wrapper catches it 
    and prints to stdout instead of crashing.
    """
    _, mock_eng, FakeMatlabExecutionError = mock_matlab
    processor = SPPMatlabProcessor("./dummy_path")
    processor.eng = mock_eng

    # Arrange: Make the engine raise a MatlabExecutionError
    mock_eng.run_spp_analysis.side_effect = FakeMatlabExecutionError("Variables missing")

    # Act
    processor.process_file("bad_file.csv")

    # Assert
    captured = capsys.readouterr()
    assert "MATLAB Error on" in captured.out
    assert "Variables missing" in captured.out


def test_process_file_catches_generic_error(mock_matlab, capsys):
    """
    Verifies that generic Python errors (e.g. file permission issues) are caught.
    """
    _, mock_eng, _ = mock_matlab
    processor = SPPMatlabProcessor("./dummy_path")
    processor.eng = mock_eng

    # Arrange: Make the engine raise a standard Exception
    mock_eng.run_spp_analysis.side_effect = Exception("Unexpected crash")

    # Act
    processor.process_file("crash_file.csv")

    # Assert
    captured = capsys.readouterr()
    assert "Python Error on" in captured.out
    assert "Unexpected crash" in captured.out