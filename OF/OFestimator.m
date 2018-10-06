function [ OF, OF_Interp ] = OFestimator( CurrFrame, opticFlow, OF_Params, SR_Params, dT )
%OFESTIMATOR - Optical flow estimation
%
%

% Determine size of input image
[M, N] = size(CurrFrame);
SRF    = SR_Params.SRF;

% Interpolate to the SR size
CurrFrame = imresize(double(CurrFrame), SRF*[M, N], 'bilinear');

% % Convert to graylevel 0 - 255
CurrFrame = CurrFrame/max(CurrFrame(:))*255;

% Perform OF estimation
OF = estimateFlow(opticFlow, double(CurrFrame));

% Output
OF_Interp = OF;

% Interpolate to the SR grid 
% OF_Interp = opticalFlow(imresize(OF.Vx*(1/dT), SRF*[M, N], 'bilinear'), imresize(OF.Vy*(1/dT), SRF*[M, N], 'bilinear'));
% OF_Interp = opticalFlow(imresize(OF.Vx, SRF*[M, N], 'bilinear'), imresize(OF.Vy, SRF*[M, N], 'bilinear'));
% OF_Interp.Vx = imresize(OF.Vx, SRF*[M, N], 'bilinear');
% OF_Interp.Vy = imresize(OF.Vy, SRF*[M, N], 'bilinear');
% OF_Interp.Magnitude   = imresize(OF.Magnitude, SRF*[M, N], 'bilinear');
% OF_Interp.Orientation = imresize(OF.Orientation, SRF*[M, N], 'bilinear');













