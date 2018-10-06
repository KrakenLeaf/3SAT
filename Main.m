clc;
clear;
close all;

%% Description
% --------------------------------------------------------------------------
% Main script to test FlowSR - Super-resolution with a flow prior
%
warning off;

% NOTE: Displaying images to screen as part of the debug process increases computation time dramatically
global DEBUG VERBOSE VIDEO
DEBUG   = 2; 
VERBOSE = 2;                            % More text as number increases
VIDEO   = -1; VideoWriter('sim_demo.avi','Uncompressed AVI');   % Create a movie,   -1 means that no movie will be created 

InternalSaveFlag = 1;   % 1 - save, 0 don't save

% Add necessary folders
FolderName = {'Utilities', 'OptEngine', 'OF', 'BubbleTracking', 'freezeColors', 'cm_and_cb_utilities'}; %Technical functions, SR optimization algorithms, Tracking related code
for tt = 1:numel(FolderName)
    addpath(genpath(FolderName{tt}));
end

% Record video only in DEBUG mode
if VIDEO ~= -1; open(VIDEO); end

%% Parameters
% --------------------------------------------------------------------------
InputConfigFile = 'ConfigFile_sim_1.txt'; 
[ MovieFolder, InputName, DataType, SaveFolder, General_Params, Acq_Params, Tracker_Params, OF_params, SR_params ] = ReadConfigFile( InputConfigFile );

% -------------------------------------------------------------------------------------------------------------------------------------------------------
%% Create save folder
% -------------------------------------------------------------------------------------------------------------------------------------------------------
if InternalSaveFlag
    % Save Output - Create a new directory inside SaveFolder
    try 
        DestFolder = [SAVE_FOLDER_PREFIX date];
    catch
        DestFolder = ['Results_' date];
    end
    if ~exist(fullfile(SaveFolder, DestFolder), 'dir')
        mkdir(SaveFolder, DestFolder);
    end
    
    % Current time stamp - Time stamp corresponds to the beginning of execution
    TimeStamp = datestr(clock);
    TimeStamp(ismember(TimeStamp, ' -:')) = ['_'];
    
    % Copy the configuration file to the specified folder
    copyfile(InputConfigFile, fullfile(SaveFolder, DestFolder, [InputConfigFile(1:end-4) '_' TimeStamp '.txt']));
end

%% Initialization
% --------------------------------------------------------------------------
% Load diffraction limited movie
[ DL_Movie, PSF ] = LoadMovie( MovieFolder, InputName, DataType );
SR_params.PSF     = PSF;

% If Movie is complex, transform to absolute value
DL_Movie = abs(DL_Movie);

% Optional - clip the movie
if General_Params.MaxNumFrames == -1
    General_Params.MaxNumFrames = size(DL_Movie, 3);
end
DL_Movie = DL_Movie(:, :, General_Params.StartNumFrames:General_Params.MaxNumFrames);

%% Run the SR reconstruction method with flow prior
% --------------------------------------------------------------------------
TotRunTime = tic;
[ SR_out, SR_out_reg, Tracks, ImagesBuffer, DetectedMB ] = FlowSR( DL_Movie, PSF, SR_params, OF_params, Tracker_Params );

% Close movie fid
if VIDEO ~= -1; close(VIDEO);end

%% Visualization
% --------------------------------------------------------------------------
% Draw velocity maps
if SR_params.FlowFlag
    % MIP or temporal mean image - currently not in use
    MIP = CreateMIP( DL_Movie, 'mip' );
    
    % Velocity tracks
    VelocityMaps2( Tracks, size(PSF)*SR_params.SRF, Acq_Params, Tracker_Params, SR_params, MIP );
end

% Plot number of detected MBs as function of frame number
figure;
plot(DetectedMB.Weighted, '-*', 'linewidth', 2); hold on
plot(DetectedMB.NonWeighted, '-*', 'linewidth', 2);
grid on;legend('weighted', 'non-weighted');
xlabel('Frame number');ylabel('Number of detected MBs');
set(gca, 'fontsize', 20);
axis([1 size(DL_Movie, 3) 0 10 + max([max(DetectedMB.Weighted) max(DetectedMB.NonWeighted)])]);

% -------------------------------------------------------------------------------------------------------------------------------------------------------
%% Construct SR image and save in desired location
% -------------------------------------------------------------------------------------------------------------------------------------------------------
if InternalSaveFlag
    if VERBOSE; disp(['Saving results in folder: ' SaveFolder]); end
    
    % Save SR results
    save([fullfile(SaveFolder, DestFolder) '/Output_' TimeStamp '.mat'], 'SR_out', 'Tracks', 'DL_Movie', 'PSF', 'DetectedMB');
%     save([fullfile(MovieParams.SaveFolder, DestFolder) '/Tracks_' TimeStamp '.mat'], 'Tracks');
end

% Display total time
disp(['Total processing time: ' num2str(toc(TotRunTime)) ' seconds.']);
































