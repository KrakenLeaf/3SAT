function [ Tracker_obj ] = MHT_init( Tracker_params )
%NHT_INIT Summary of this function goes here
%   Detailed explanation goes here
%
%

%% Add required files to java classpath
% ------------------------------------------------------------------------------
tracker_instalation_path = fullfile(pwd, 'BubbleTracking', 'MHT');%eval('pBubbleTracking\MHT');

files = {
    'dist/lib/collections-generic-4.01.jar'
    'dist/lib/jaxb-api.jar'
    'dist/lib/jung-algorithms-2.0.jar'
    'dist/lib/jung-graph-impl-2.0.jar'
    'dist/lib/jung-visualization-2.0.jar'
    'dist/lib/junit-4.5.jar'
    'dist/lib/LisbonMHL-1.0.jar'
    'dist/lib/log4j-1.2.15.jar'
    'dist/lib/MHL2.jar'
    'dist/lib/Murty.jar'
    'dist/MatlabExampleApp.jar'};

for ii = 1:length(files)
    javaaddpath(fullfile(tracker_instalation_path, files{ii}));
end

%% Initialize tracker object 
% ------------------------------------------------------------------------------
Tracker_obj = com.multiplehypothesis.simpletracker.tracker.MTracker(...
              Tracker_params.maxNumLeaves,...   % int maxNumLeaves
              Tracker_params.maxDepth,...       % int maxDepth
              Tracker_params.timeUndetected,... % int timeUndetected      - Time in frames to close a track if no measurement was associated to it
              Tracker_params.bestK,...          % int bestK
              Tracker_params.probUndetected,... % double probUndetected   - Probability for not detecting a bubble which exists
              Tracker_params.probNewTarget,...  % double probNewTarget    - Probability for a new target to appear
              Tracker_params.probFalseAlarm,... % double probFalseAlarm   - Probability of false alarm (detection while there is no taget) 
              Tracker_params.gateSize...        % double gateSize         - Radius in pixels of expected target
              );








