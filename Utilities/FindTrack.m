function [SubTracks] = FindTrack(Tracks, IDs)
%FINDTRACK Summary of this function goes here
%   Detailed explanation goes here

%% Initialize
SubTracks = {};

%% Find the tracks with track IDs
Counter = 1;
for jj = 1:numel(Tracks)
    for ii = 1:length(IDs)
        if Tracks{jj}.ID == IDs(ii)
           % Found track
           SubTracks{Counter} = Tracks{jj}; 
           
           % Counter
           Counter = Counter + 1;
        end
    end
end

















end

