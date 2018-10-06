function [] = run_tracker_mod( avi )
%TRACKER Summary of this function goes here
%   Detailed explanation goes here

%% Load example video
if nargin == 0
    avi = VideoReader('ants.avi');
end

%% Configuration
tracker_instalation_path = eval('pwd');
edge_treshold = 0.35; % The lower the value, the more edges are detected
morphological_closing_square_size = 5; % The value should be greater if the targets are bigger
binary_threshold = 0.5; % The threshold for creating the binary image
min_blob_area = 100; % Minimum blob area
use_blob_colors = false;

%% Add required files to java classpath

files= {
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

for i=1:length(files)
    eval(['javaaddpath ' tracker_instalation_path '/' files{i}]);
end

%% Create tracker

tracker = com.multiplehypothesis.simpletracker.tracker.MTracker(...
    6,... % int maxNumLeaves
    6,... % int maxDepth
    10,... % int timeUndetected
    6,... % int bestK
    0.1,... % double probUndetected
    0.001,... % double probNewTarget
    0.01,... % double probFalseAlarm
    30 ... % double gateSize
    );

%% Grayscale convertion
original_frames = {};
i = 1;
while hasFrame(avi)
    original_frames{i} = readFrame(avi);
    i = i + 1;
end
frames = {};
fprintf(1, 'Converting images to grayscale...\n');
for i=1:length(original_frames)
    frames{i} = rgb2gray(original_frames{i});
end

background = frames{1};

%fig = figure(1);
%imshow(background);

fig = figure(1);

%% Tracking loop

fprintf(1, 'Starting tracking...\n');
for i=1:length(frames)
    
    fprintf(1, 'Frame %d\n', i);
    
    foreground = subtractbackground(frames{i}, background);
    %imshow(foreground);
    %drawnow;
    
    edges = edge(foreground, 'canny', edge_treshold) + foreground;
    %     imshow(edges);
    %     drawnow;
    
    sedisk = strel('square',morphological_closing_square_size);
    edges = imclose(edges, sedisk);
    filled = imfill(edges,'holes');
    %     imshow(filled);
    %     drawnow;
    
    binary = filled > binary_threshold;
    
    stats = regionprops(binary,'basic','Centroid');
    imshow(original_frames{i});
    %imshow(binary);
    hold on
    
    detections = [];
    for n = 1:length(stats)
        if(stats(n).Area > min_blob_area)
            plot(stats(n).Centroid(1), stats(n).Centroid(2), 'r*')
            detections(end+1,:) = [stats(n).Centroid(1) stats(n).Centroid(2)];
        end
    end
    
    targets = tracker.newScan(detections);
    if sum(size(targets)>0)==2
        for j=1:size(targets,1)
            textprops = '\fontsize{16}';
            if use_blob_colors
                textprops = [textprops ' \color[rgb]{' getColor(targets(j,4)) '}'];
            else
                textprops = [textprops ' \color{green}'];
            end
            text(targets(j,1),targets(j,2), [textprops sprintf(' %d',targets(j,3))]);
        end
    end
    
    drawnow;
    hold off
    
    %waitforbuttonpress
end

return

function [foreground] = subtractbackground( frame, background )

foreground = (abs(im2double(background)-im2double(frame)));

return

function [color] = getColor(i)

pool = 200;
i = mod(i, pool) + 1;
colors = hsv(pool + 1);
color = sprintf('%d %d %d', colors(i, 1), colors(i, 2), colors(i, 3));

return


