function TracksHistLength(Tracks, varargin)
%TRACKSHISTLENGTH Summary of this function goes here
%   Detailed explanation goes here

% Physical size of each pixel
if nargin > 1
    dX = varargin{1};
else 
    dX = 1;
end

% Measure each track length in number of measurements and total length
Tlengths = zeros(numel(Tracks), 1);
Totlen   = zeros(numel(Tracks), 1);
for ii = 1:numel(Tracks)
    % Number of measurements
    Tlengths(ii) = size(Tracks{ii}.Measurement, 2);
    
    % Total length
    if size(Tracks{ii}.Measurement, 1) == 5
        X = [Tracks{ii}.Measurement(2, 1), Tracks{ii}.Measurement(2, end)];
        Y = [Tracks{ii}.Measurement(4, 1), Tracks{ii}.Measurement(4, end)];
    else
        X = [Tracks{ii}.Measurement(2, 1), Tracks{ii}.Measurement(2, end)];
        Y = [Tracks{ii}.Measurement(5, 1), Tracks{ii}.Measurement(5, end)];
    end
    Totlen(ii) = sqrt((X(1) - X(2))^2 + (Y(1) - Y(2))^2)*dX;
end

% Histogram of track lengths
Nbins = 50;
subplot(121);
histogram(Tlengths, Nbins);grid on;
xlabel('Track lengths');ylabel('Counts');title('Track lengths histogram');
subplot(122);
stem(Totlen);grid on;
xlabel('Track lengths - physical');ylabel('distance [mm]');title('Track lengths histogram');



end

