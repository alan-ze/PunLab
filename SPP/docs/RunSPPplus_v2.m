clc
clear
close all

format long G;  % 15 signficant digits

% This code calculates the Sequence of Physical Processes (SPP) metrics for
% a given dataset. These metrics are outlined in detail in the papers:
% "Rogers SA (2017) In search of physical meaning: defining transient
% parameters for nonlinear viscoelasticity. Rheol Acta 56:501-525" amd
% "Donley GJ et al. (2019) Time-resolved dynamics of the yielding
% transition in soft materials. JNNFM 58:361-382"

% The procedure reads data from either a .txt file or a .csv file and
% calculates and outputs the results based on both Fourier domain filtering
% (SPPplus_fourier_v2) and/or numerical differentiation
% (SPPbasic_numerical_v1) analysis methods.

% FOR ALL INUTS -> All input data should be in column form. The prefered
% order of variable columns is Time, Strain, Rate, Stress. If the file is
% not in this order, specify the locations of these columns in the variable
% "var_loc". The code assumes the following units: Time (s), Strain (-),
% Rate (1/s), and Stress (Pa). If the units in the input data are
% different, specify the conversion factors in the variable 'var_conv'. If
% only a portion of the points in your file are needed for your analysis,
% the data can be truncated (specified by the variable "data_trunc").

% IF THE INPUT IS .TXT -> The imported file MUST contain exactly 4 columns:
% Time, Strain, Rate, and Stress. (If no rate data is avalible and the data
% is steady state oscilatory, a 3 column file with Time, Strain, and Stress
% MUST be used.) The file MUST NOT contain header rows, as these disrupt
% the import process.

% IF THE INPUT IS .CSV -> The imported file must contain at least 4
% columns. (3 if rate is to be differentiated internally.) The file can
% contain header rows, as well as additional unused columns.

% IF USING THE FOURIER ANALYSIS -> The code requires that the number of
% periods of oscilation MUST BE AN INTEGER. Additionally, it is recomended
% to use an even number of data points in each period of oscilation. These
% allow for the computation of a fourier series fitting the input data.

% IF USING THE NUMERICAL ANALYSIS -> There are two modes for numerical
% differentation. The standard mode (#1) can be used for all data. The
% looped mode (#2) can only be used for steady state oscilatory data, but
% is more acurate for that data.

% SPPplus version #2.1
% Finalized on May 28th 2021 by Gavin Donley @Georgetown and Simon Rogers @UIUC

%=======================User-defined variables=============================

% DATA IMPORT SETTINGS 
fname = "TJC2_36C4_Sine Strain - 2"; % Input data file name (do NOT include extension) (must be
	%either .txt OR .csv) (Note restrictions on data mentioned above)
ftype = 2; % What type of file is being imported
	%use 1 if .txt file 
	%use 2 if .csv file
var_loc = [1,2,3,4]; % Location of each data column in imported file (Time,
    %Strain, Rate, Stress). All inputs MUST be positive integers, except 
    %Rate (3rd index), which can be set to zero to indicate that rate needs
    %to be differentiated from strain. (This differentiation only supports
    %closed-loop periodic data currently)
var_conv = [1,0.01,1,1]; % Conversion factors required to put the data in
    %the assumed units: Time (s), Strain (-), Rate (1/s), and Stress (Pa),
    %with each index corresponding the units of the four variables in that
    %order. Conversion factors will multiply the data as follows:
    %   (data in file)*(conversion factor)=(data in correct units)
data_trunc = [0,1,287]; % Determines if/how data will be truncated.
    %First index denotes whether truncation of input data will occur
        %if 1, data will be truncated
    %Second and third indeces denote the 1st and last points to keep when
    %truncating dataset
    
% ANALYSIS SETTINGS
an_use = [1,0]; % Determines what analyses to run.
    %First index denotes whether a fourier series will be used
        %if 1, SPPbasic_fourier_v1 will be run
    %Second index denotes whether a numerical differentiation will be used
        %if 1, SPPbasic_numerical_v1 will be run
omega=0.628; %frequency of oscilation, in units of rad/s
    %For Fourier mode, this must be a single number
    %For Numerical mode, this can either be a single number OR a vector
        %with the same length as the data
% IF FOURIER DOMAIN FILTERING IS USED
M=7; % The number of harmonics to be used in reconstruction of stress.
	%(Must be an odd integer)
p=1; % Total number of periods of measuring time, which we have to know in
	%order to do FT. (Must be a positive integer)
% IF NUMERICAL DIFFERENTIATION IS USED
k=1; % Step size for numerical differentiation, default to be 1. (Must be
	%a positive integer)
num_mode=1; %method of numerical differentiation
	%1 = "standard" (does not make assumtions abot the form of the data, 
        %uses forward/backward difference at ends and centered derivative 
        %elsewhere)
	%2 = "looped" (assumes steady state oscilatory, uses centered 
        %difference everywhere by connecting the data in a loop) (must be a
        %closed periodic curve to utilize)

% OUTPUT SETTINGS
out_type = 1; % What type of file is being exported
	%use 1 if .txt file 
	%use 2 if .mat file
is_fsf = 1; % Print full frenet-serret frame data?
    %if 0, only the standard SPP data file will be produced
        %(waveforms, time dependent moduli, moduli rates, etc.)
        %(ex. sample_file1_SPP_LAOS_FOURIER.txt)
	%if 1, second extended data file will be produced
        %(includes components of Tangent, Normal, & Binormal vectors)
        %(ex. sample_file1_SPP_LAOS_FOURIER_FSF.txt)
save_figs = 0; % Save figures of the SPP metrics ?
	%if 0, figures will be displayed but not saved
	%if 1, all figures will be saved as image files
	%(ex. sample_file1_SPP_LAOS_FOURIER_PLOT.jpg)
	%note: the exact figures produced will depend on the chosen analyses

%=======================Run the SPP analysis===============================

%Read and extract data from file
[time_wave,resp_wave,L,fname_t] = SPPplus_read_v2(fname,ftype,var_loc,...
    var_conv,data_trunc);

%Condense output params.
out_set=[out_type,is_fsf,save_figs];

%Run Fourier Domain Filtering analysis
if an_use(1) == 1
    SPPplus_fourier_v2(time_wave,resp_wave,L,omega,M,p,out_set,fname_t);
end

%Run Numerical Differentiation analysis
if an_use(2) == 1
    SPPplus_numerical_v2(time_wave,resp_wave,L,omega,k,num_mode,out_set,...
        fname_t);
end

%Thank you for using SPPplus.
