function [ EstState, Pout ] = KalmanPropagator( State, P, Q, Params )
%PROPAGATOR - Kalman filter propagation for a single bubble
%
%
% EstState = x_{n|n-1}
% Pout     = P_{n|n-1}
% 

global VERBOSE

%% Initialization
% -------------------------------------------------------------------------
TimeStamp = State(1);              % Measurement time-stamp
PrevState = State(2:end);          % Measurement
Ns        = length(PrevState);     % Length of state vector

dT        = Params.dT;             % dT between concecutive frames. Typically dT = 1;
Trate     = Params.Trate;          % Extrapolation factor between measuremets. Assume to be an integer >= 1 for simplicity

dt_extrap = dT/Trate;              % Extrapolation time stamps

EstState  = zeros(Ns + 1, Trate);  % Output prediction values - does not include current state. All extrapolated states will be concatenated to current state

TimeVec   = TimeStamp + dt_extrap:dt_extrap:TimeStamp + dt_extrap*Trate; % Extrapolation time-stamps

MaxVel    = Params.MaxVel;         % Maximum allowed velocity between frames
MaxAcc    = Params.MaxAcc;         % Maximum allowed acceleration between frames

% Model matrices
Phi       = Params.Phi;
PhiTot    = Params.PhiTot;

%% State extrapolation
% -------------------------------------------------------------------------
for ii = 1:Trate
    % Maximum velocity check
    if Params.StateSize == 6
        CurrVel = sqrt(PrevState(2)^2 + PrevState(5)^2);
        CurrAcc = sqrt(PrevState(3)^2 + PrevState(6)^2);
    else
        CurrVel = sqrt(PrevState(2)^2 + PrevState(4)^2);
        CurrAcc = 0;
    end
    
    if CurrVel > MaxVel + dt_extrap*MaxAcc %|| CurrAcc > MaxAcc
        % Velocity or acceleration exceeded maximum bound
        x = PrevState;
        
        if VERBOSE >= 2; disp(['KalmanPropagator: Velocity error bounds ' num2str(CurrVel) ' pixels/dT. Time = ' num2str(TimeVec(ii)) '.']); end;
    else
        % Velocity is valid
        x = Phi*PrevState;             % State extrapolation - [X Vx Ax Y Vy Ay]^T
    end
    
    % Output
    EstState(:, ii) = [TimeVec(ii); x];
    
    % Update previous state estimate
    PrevState = x;
end

% Covariance extrapolation - updated only once at the last iteration

Pout = PhiTot*P*PhiTot' + Q;



















































