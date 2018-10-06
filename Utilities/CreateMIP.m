function [ MIP ] = CreateMIP( MovieIn, varargin )
%CREATEMIP generate the diffraction limited MIP or temporal mean image
%
%
%

%% Initialization
% -------------------------------------------------------------------------
if nargin > 1
    Type = varargin{1};
else
    Type = 'mip';
end

%% Generate image
% -------------------------------------------------------------------------
switch lower(Type)
    case 'mip'  % Maximum intensity projection
        MIP = max(abs(MovieIn), [], 3);
    case 'mean' % Temporal mean
        MIP = sum(abs(MovieIn), 3);
    otherwise
        error('CreateMIP: Type not supported.');
end
