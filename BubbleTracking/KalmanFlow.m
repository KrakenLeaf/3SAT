function [ EstState, P_out ] = KalmanFlow( PrevState, MesFlow, P, Q, R, Params )
%KALMANFLOW - Kalman estimation of optical flow from SR frames. This function
% tracks a single bubble. Thus it must be applied for each bubble separately.
%
% Model:
% ------
% x_n   = Phi_n*x_(n-1) + w_n
% x_n   = [x v_x_n a_x_n y v_y_n a_y_n]^T
% Phi_n = [1 dT 0.5*dT^2 0 0  0
%          0 1  dT       0 0  0
%          0 0  1        0 0  0
%          0 0  0        1 dT 0.5*dT^2
%          0 0  0        0 1  dT
%          0 0  0        0 0  1]
%
%
% inputs:
% -------
% PrevState - Estimated optical flow from previous frame
% MesFlow  - Measured flow at current frame
% P        -
% Q        - Model covariance matrix. Dimensions:
% R        - Measurement covariance matrix. Dimensions:
%

%% Initialization
% -------------------------------------------------------------------------
TimeStamp = PrevState(1);          % Measurement time-stamp
LastState = PrevState(2:end);      % Last step is updated with the current measurement MesFlow

% Model matrices
H = Params.H;

%% State update with measurement
% -------------------------------------------------------------------------
% Kalman gain calculation
K = P*H'*pinv(H*P*H' + R);  % pinv - Moore-Penrose pseuo-inverse (more numerically stable than inv, also inv func can be used)

% Innovation calculation
Inov = MesFlow - H*LastState;

% State update
LastState = LastState + K*Inov;

% Error covariance update
P_out = P - K*H*P;

% Add time vector
EstState = [TimeStamp; LastState];

    
    
    
    
