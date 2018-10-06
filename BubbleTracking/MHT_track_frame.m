function [ Targets, DetectedMB_stack ] = MHT_track_frame( Frame_in, tracker, DetectedMB_stack )
%MHT_TRACK_FRAME Summary of this function goes here
%   Detailed explanation goes here
%
% Syntax:
% -------
% [ targets ] = MHT_track_frame( Frame_in )
%
% Inputs:
% -------
% Frame_in - Input frame to process
%
% Outputs:
% --------
% Targets  - Tracked targets
%

%% Pre-process input frame - optional
Detections = Frame_PreProcess(Frame_in);

%% Perform tracking and track association
Targets    = tracker.newScan(Detections);

%% Number of detected MBs
DetectedMB_stack = [DetectedMB_stack size(Detections, 1)];


%% Auxiliary functions
% ------------------------------------------------------------------------------
function Detections = Frame_PreProcess(Frame_in)
% Internal parameters
edge_treshold                     = 0.2; % The lower the value, the more edges are detected
morphological_closing_square_size = 5; % The value should be greater if the targets are bigger
binary_threshold                  = 0.5; % The threshold for creating the binary image
min_blob_area                     = 2; % Minimum blob area

% Image pre-processing on input frame
edges  = edge(Frame_in, 'canny', edge_treshold) + Frame_in;

sedisk = strel('square',morphological_closing_square_size);
edges  = imclose(edges, sedisk);
filled = imfill(edges,'holes');

binary = filled > binary_threshold;

stats  = regionprops(binary, 'basic', 'Centroid');

% Accumulate detections
Detections = [];
for n = 1:length(stats)
    if(stats(n).Area > min_blob_area)
%         plot(stats(n).Centroid(1), stats(n).Centroid(2), 'b*')
        Detections(end+1,:) = [stats(n).Centroid(1) stats(n).Centroid(2)];
    end
end






