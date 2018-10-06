function [ opticFlow ] = OFestimator_Preprocess( Params )
%OFESTIMATOR_PREPROCESS Summary of this function goes here
%   Detailed explanation goes here
%
%
%

% Perform OF pre-processing according to selected method
switch lower(Params.Method)
    case 'lkdog'
        opticFlow = opticalFlowLKDoG('NumFrames', 3, 'ImageFilterSigma', 1.5, 'GradientFilterSigma', 1, 'NoiseThreshold', 10); 
    case 'lk' % Lukas - Kanade
        opticFlow = opticalFlowLK('NoiseThreshold', Params.lk_NoiseThreshold);
    case 'hs' % Horn-Schunck
        opticFlow = opticalFlowHS('Smoothness', 1000, 'MaxIteration', 10, 'VelocityDifference', 0);
    case 'farneback'
        opticFlow = opticalFlowFarneback('PyramidScale', 0.5, 'NumIterations', 3, 'NeighborhoodSize', 30, 'FilterSize', 15);
    otherwise
        error('OFestimator: Method not supported.');
end




















