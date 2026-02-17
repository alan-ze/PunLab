% Save this as: run_spp_analysis.m
function run_spp_analysis(fname_input, varargin)
    % Accepts 'fname_input' from Python.
    % Optional: You can pass other overrides via varargin if needed later.

    % --- CRITICAL CHANGES ---
    % 1. REMOVED 'clear' so we don't wipe arguments passed from Python.
    % 2. REMOVED 'close all' to prevent MATLAB from stealing focus if plotting.
    % clc; % Optional: keeps terminal clean

    format long G;

    % =======================User-defined variables=============================

    % DATA IMPORT SETTINGS
    % Logic: If Python passed a filename, use it. Otherwise, default (for testing).
    if nargin > 0
        fname = fname_input;
    else
        fname = "TJC2_36C4_Sine Strain - 2"; 
    end

    % --- (The rest of your hardcoded config) ---
    % Note: If you want Python to control these, you must add them as arguments
    % to the function header above, similar to fname.

    ftype = 2; 
    var_loc = [1,2,3,4];
    var_conv = [1,1,1,1];
    data_trunc = [0,1,287];

    % ANALYSIS SETTINGS
    an_use = [1,0];
    omega = 0.628;

    % FOURIER SETTINGS
    M = 7;
    p = 1;

    % NUMERICAL DIFFERENTIATION SETTINGS
    k = 1;
    num_mode = 1;

    % OUTPUT SETTINGS
    out_type = 1;
    is_fsf = 0;
    save_figs = 0; % Keep 0 for batch processing to avoid popup windows

    % =======================Run the SPP analysis===============================

    % Add error handling for path/file issues
    if ~isfile(strcat(fname, '.csv')) && ~isfile(strcat(fname, '.txt'))
        error('MATLAB:FileNotFound', 'The file %s was not found.', fname);
    end

    % Read and extract data from file
    [time_wave,resp_wave,L,fname_t] = SPPplus_read_v2(fname,ftype,var_loc,...
        var_conv,data_trunc);

    % Condense output params.
    out_set=[out_type,is_fsf,save_figs];

    % Run Fourier Domain Filtering analysis
    if an_use(1) == 1
        SPPplus_fourier_v2(time_wave,resp_wave,L,omega,M,p,out_set,fname_t);
    end

    % Run Numerical Differentiation analysis
    if an_use(2) == 1
        SPPplus_numerical_v2(time_wave,resp_wave,L,omega,k,num_mode,out_set,...
            fname_t);
    end
end