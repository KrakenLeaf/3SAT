function [ImageOut, ImageOutFiltered] = Tracks2Image(Tracks, ImageSize, h, varargin)
%TRACKS2IMAGE Summary of this function goes here
%
%
%

% Initialization
% -------------------------------------------------------------------------
% Max velocity
if nargin == 4
    MaxVel = varargin{1};
else
    MaxVel = 1e60;
end

ImageOut = zeros(ImageSize);

% Determine state size
StateSize = size(Tracks{1}.State, 1);

if StateSize == 7
    Inds    = [2 5]; % [Time X Vx Ax Y Vy Ay]
    VelInds = [3 6];
else
    Inds    = [2 4]; % [Time X Vx Y Vy]
    VelInds = [3 5];
end

InterpFactor = 10;

% % % % Smoothing
% % % % h = fspecial('Gaussian',10*[1,1],1);
% % % h = fspecial('Gaussian',10*[1,1],2); % Only for the simulation

% Plot
% -------------------------------------------------------------------------
for jj = 1:numel(Tracks)
    Points   = [Tracks{jj}.State(Inds(1), :); Tracks{jj}.State(Inds(2), :)];
    VelPnts  = [Tracks{jj}.State(VelInds(1), :); Tracks{jj}.State(VelInds(2), :)];
    Time     = Tracks{jj}.State(1, :);
    
    Vels = sqrt(VelPnts(1, :).^2 + VelPnts(2, :).^2);
    if ~isempty(MaxVel) && max(Vels) <= MaxVel
        % Interpolate points
        Points   = InterPoints(Points, Time, InterpFactor);
        
        ImageOut = CreateImageFromPoints(ImageOut, Points, ImageSize);
    end
end

% Output final image
if ~isempty(h)
    ImageOutFiltered = imfilter(double(imbinarize(ImageOut)), h.^0.75);
else
    ImageOutFiltered = double(imbinarize(ImageOut));
end

end




%% Auxiliary functions
% -------------------------------------------------------------------------
function PointsInterp = InterPoints(Points, Time, InterpFactor)
method             = 'spline';
TimeInterp         = linspace(Time(1), Time(end), length(Time)*InterpFactor);
PointsInterp(1, :) = interp1(Time, Points(1, :),  TimeInterp, method);
PointsInterp(2, :) = interp1(Time, Points(2, :),  TimeInterp, method);
end


function TrkFrame = CreateImageFromPoints(TrkFrameIn, Points, SizeFrame)
% Initialize empty image
TrkFrame = TrkFrameIn;

% Points is the XY coordinates of a single track [X; Y]
PointsRound = round(Points);

% Find out of bounds indices and discard them
IndsTmpX    = find(PointsRound(1,:).' >= 1 & PointsRound(1,:).' <= SizeFrame(1));
IndsTmpY    = find(PointsRound(2,:).' >= 1 & PointsRound(2,:).' <= SizeFrame(2));
[C, IX, IY] = intersect(IndsTmpX, IndsTmpY);

% Put 1's where there is a point emitter
try
    % This is the original line - catch is only for debug. Should be deleted later on
    Inds = sub2ind(size(TrkFrame), PointsRound(1,IX).', PointsRound(2, IY).');
    TrkFrame(Inds) = 1;
end

end







