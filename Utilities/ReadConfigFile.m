function [ MovieFolder, InputName, DataType, SaveFolder, General_Params, Acq_Params, Tracker_Params, OF_params, SR_params ] = ReadConfigFile( InputConfigFile, varargin )
% READCONFIGFILE - This function read a TXT file which containts all of the
% configuration definitions for the SRFM script.
%
% Syntax:
% -------
% [ FullMovieLength, MovieBlockLength, GenParams, MovieParams, PSFParams, WienerParams, AlgParams ] = ReadConfigFile( fid )
%
% Inputs:
% -------
% InputConfigFile - Name of configuration TXT file
% inFolder        - Directory in which the configuration file is located (optional)
%
% Outputs:
% --------
% GenParams       - General parameters
% MovieParams     - Movie parameters
% PSFParams       - PSF parameters
% WienerParams    - Filtering parameters
% AlgParams       - Solver parameters
%
% Ver 1. Written by Oren Solomon, Technion I.I.T. 21-01-2018
%

%% Initializations
% ------------------------------------------------------------------------------------------------------------------
% InputConfigFile directory
if nargin > 1
    inFolder = varargin{1};
else
    inFolder = '.';
end

% Open file
fid = fopen(fullfile(inFolder, InputConfigFile), 'r');

%% Parse each line in InputConfigFile
% ------------------------------------------------------------------------------------------------------------------
% 											General parameters 											 %
% --------------------------------------------------------------------------------------------------------
MovieFolder = SearchLine(fid, 'MovieFolder');                                                            % Location of the movie - includes also the PSF
InputName   = SearchLine(fid, 'InputName');                                                              % Movie name
DataType    = SearchLine(fid, 'DataType');                                                               % Type of movie - currently only MAT file is supported
SaveFolder  = SearchLine(fid, 'SaveFolder');

General_Params.StartNumFrames = str2num(SearchLine(fid, 'General_Params.StartNumFrames'));
General_Params.MaxNumFrames   = str2num(SearchLine(fid, 'General_Params.MaxNumFrames'));


% 							  		Physical acquisition parameters 									 %
% --------------------------------------------------------------------------------------------------------
Acq_Params.FrameRate  = str2num(SearchLine(fid, 'Acq_Params.FrameRate'));        						 % US movie frame-rate [Hz]
Acq_Params.PixelSizes = str2num(SearchLine(fid, 'Acq_Params.PixelSizes'));								 % US movie pixel size (x, z) [mm]


% 										  Tracker parameters 										     %
% --------------------------------------------------------------------------------------------------------
Tracker_Params.maxNumLeaves   = str2num(SearchLine(fid, 'Tracker_Params.maxNumLeaves'));	   			 % int maxNumLeaves
Tracker_Params.maxDepth       = str2num(SearchLine(fid, 'Tracker_Params.maxDepth'));	    			 % int maxDepth
Tracker_Params.timeUndetected = str2num(SearchLine(fid, 'Tracker_Params.timeUndetected'));	  			 % int timeUndetected      - Time in frames to close a track if no measurement was associated to it
Tracker_Params.bestK          = str2num(SearchLine(fid, 'Tracker_Params.bestK'));	   					 % int bestK
Tracker_Params.probUndetected = str2num(SearchLine(fid, 'Tracker_Params.probUndetected'));	 			 % double probUndetected   - Probability for not detecting a bubble which exists
Tracker_Params.probNewTarget  = str2num(SearchLine(fid, 'Tracker_Params.probNewTarget'));	 			 % double probNewTarget    - Probability for a new target to appear
Tracker_Params.probFalseAlarm = str2num(SearchLine(fid, 'Tracker_Params.probFalseAlarm'));	 			 % double probFalseAlarm   - Probability of false alarm (detection while there is no taget)
Tracker_Params.gateSize       = str2num(SearchLine(fid, 'Tracker_Params.gateSize'));	

Tracker_Params.KF.dT          = str2num(SearchLine(fid, 'Tracker_Params.KF.dT'));      					 % In frames, thast is if dT = 1 then the next measurement is in the next frame
Tracker_Params.KF.Trate       = str2num(SearchLine(fid, 'Tracker_Params.KF.Trate'));     				 % Number of extrapolation points between each dT
Tracker_Params.KF.MaxVel      = str2num(SearchLine(fid, 'Tracker_Params.KF.MaxVel'));   				 % Maximum allowed velocity - [pixels/dT]
Tracker_Params.KF.MaxAcc      = str2num(SearchLine(fid, 'Tracker_Params.KF.MaxAcc'));   				 % Maximum allowed acceleration - [pixels/dT^2]
Tracker_Params.KF.UseVel      = str2num(SearchLine(fid, 'Tracker_Params.KF.UseVel'));    				 % 1 - use velocities in the filtering process
Tracker_Params.KF.ModelType   = str2num(SearchLine(fid, 'Tracker_Params.KF.ModelType'));   				 % 1 - [Pos, Vel, Acc], 2 - [Pos, Vel]
Tracker_Params.KF.Q           = eval(SearchLine(fid, 'Tracker_Params.KF.Q'));                            % Model covariance matrix  				 
Tracker_Params.KF.R           = eval(SearchLine(fid, 'Tracker_Params.KF.R'));                            % Measurement covariance matrix
Tracker_Params.KF.rho 		  = str2num(SearchLine(fid, 'Tracker_Params.KF.rho'));                      

% 										Optical flow parameters 										 %
% --------------------------------------------------------------------------------------------------------
OF_params.Method              = SearchLine(fid, 'OF_params.Method');
OF_params.BurnIn              = str2num(SearchLine(fid, 'OF_params.BurnIn'));
OF_params.lk_NoiseThreshold   = str2num(SearchLine(fid, 'OF_params.lk_NoiseThreshold'));
OF_params.UniformIntensity    = str2num(SearchLine(fid, 'OF_params.UniformIntensity'));      			 % 1 - Binarize intensities of SR frame and convolve with a Gaussian


% 							   Sparse recovery parameters parameters   									 %
% --------------------------------------------------------------------------------------------------------
% Solver type
SR_params.SolverType = SearchLine(fid, 'SR_params.SolverType');

% SR solver parameters
SR_params.SRF        = str2num(SearchLine(fid, 'SR_params.SRF'));                                        % Super resolution factor
SR_params.Beta       = str2num(SearchLine(fid, 'SR_params.Beta'));
SR_params.L0         = str2num(SearchLine(fid, 'SR_params.L0'));                                         % Lipschitz constant
SR_params.LambdaBar  = str2num(SearchLine(fid, 'SR_params.LambdaBar'));
SR_params.Eps        = str2num(SearchLine(fid, 'SR_params.Eps'));                                        % Weighting matrix numerical regularization - very small value = no detections. Very high velue = many detections [0.1 - 1]
SR_params.Lambda     = str2num(SearchLine(fid, 'SR_params.Lambda'));                                     % l_1 regularization
SR_params.N          = str2num(SearchLine(fid, 'SR_params.N'));                                          % Length of x
SR_params.IterMax    = str2num(SearchLine(fid, 'SR_params.IterMax'));
SR_params.NonNegOrth = str2num(SearchLine(fid, 'SR_params.NonNegOrth'));
SR_params.FlowFlag   = str2num(SearchLine(fid, 'SR_params.FlowFlag'));                                   % 1 - Use velocities in the SR process 

% FISTA Iterative
SR_params.Iterative.NumOfSteps = str2num(SearchLine(fid, 'SR_params.Iterative.NumOfSteps'));
SR_params.Iterative.Eps        = str2num(SearchLine(fid, 'SR_params.Iterative.Eps'));					 % Lower value = sparser solutions


% Close file
fclose(fid);

%% Auxiliary functions
% ------------------------------------------------------------------------------------------------------------------
function [ tStr ] = SearchLine(fid, match_str)
% Search for a line in "fid" which begins with "match_str" and read the
% relevant parameter

% Initialize tStr
tStr = [];

% Set cursor to beginning of file
fseek(fid, 0, 'bof');

while ~feof(fid) 
    % Read a line from the file
    tline = fgetl(fid);
    
    % Determine type of line
    if ~isempty(tline)                                                          % Not an empty line
        if tline(1) ~= '%'                                                      % Line is not a comment line
            % Line beginning with '%' is a comment and should be disregarded
            str_ind  = strfind(tline, match_str);
            
            % We found the string that we wanted
            if ~isempty(str_ind)
                ind1 = strfind(tline, '=');
                ind2 = strfind(tline, ';');                                    % Every line must end with ';'

                % Read the value
                tStr = strtrim(tline(ind1(1) + 1:ind2 - 1));
                
                % Clean ' if there are any in the string
                k    = strfind(tStr, '''');
                if ~isempty(k)
                    tStr = tStr(k(1) + 1:k(2) - 1);
                end
                
                % Exit the loop
                break;
            end
        end
    end
end

























