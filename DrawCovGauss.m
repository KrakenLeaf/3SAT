function [ GaussianMap ] = DrawCovGauss( Points, CovMat, ImSize )
%DRAWCOVGAUSS - plots Gaussians at positions described by Points, with 
% covariance matrices from Cob=vMat
%
% Syntax:
% -------
% [ GaussianMap ] = DrawCovGauss( Points, CovMat, ImSize )
%
% Inputs:
% -------
% Points: [x1 x2 ... xn
%          y1 y2 ... yn]
% CovMat: [vec(Cov1) vec(cov2) ... vec(covn)]
% ImSize: [RowSize ColSize]
%
% Output:
% -------
% GaussianMap: ImSize image of Gaussians
%

%% Initialization
% ------------------------------------------------------------------------------
GaussianMap = zeros(ImSize);

% Create mesh-grid
[X, Y] = meshgrid(1:ImSize(1), 1:ImSize(2));

%% Plot the Gaussians
% ------------------------------------------------------------------------------
for ii = 1:size(Points, 2)
    % Points is the XY coordinates of a single track [X; Y]
    PointsRound = Points(:, ii);
    
    % Find out of bounds indices and discard them
    FlagX = PointsRound(1).' >= 1 & PointsRound(1).' <= ImSize(1);
    FlagY = PointsRound(2).' >= 1 & PointsRound(2).' <= ImSize(2);
    
    % Draw Gaussian only if both indices are inside the frame
    if FlagX && FlagY
        Tmp = GaussDist(X, Y, PointsRound, reshape(CovMat(:, ii), [2 2]));
        GaussianMap = GaussianMap + Tmp;
    end
end

%% Auxiliary functions
% ------------------------------------------------------------------------------
function GaussOut =  GaussDist(X, Y, X0, CovMat)
% Acaling factor
A        = (det(2*pi*CovMat))^(-0.5);

% Standard deviations and correlation coefficient
SigX2    = CovMat(1, 1);
SigY2    = CovMat(2, 2);
ro       = CovMat(1, 2)/(sqrt(SigX2)*sqrt(SigY2));

% Additional parameters
Q        = 1/(2*(1 - ro^2));
c        = 2*ro/(sqrt(SigX2)*sqrt(SigY2));

% Draw the Gaussian
GaussOut = A*exp( -Q*( ((X - X0(1)).^2)/SigX2 + ((Y - X0(2)).^2)/SigY2 -c*(X - X0(1)).*(Y - X0(2)) ) );

















