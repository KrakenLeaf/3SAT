function [ ParamsOut ] = KalmanCreateMatrixModel( Params )
%KALMANCREATEMATRIXMODEL - Creates the Kalman filter matrix models
%
%
%

%% Initialization
% -------------------------------------------------------------------------
dT        = Params.dT;             % dT between concecutive frames. Typically dT = 1;
Trate     = Params.Trate;          % Extrapolation factor between measuremets. Assume to be an integer >= 1 for simplicity

dt_extrap = dT/Trate;              % Extrapolation time stamps

ParamsOut = Params;

%% Model propagation
% -------------------------------------------------------------------------
if Params.ModelType == 2
    % Do not use velocities in the estimation process
    A      = [1 dt_extrap;...
              0 1];
    
    Phi    = [A zeros(2);...        % Propagation model
              zeros(2) A];
    
    ATot   = [1 dT;...
              0 1];
    
    PhiTot = [ATot zeros(2);...     % Propagation model
              zeros(2) ATot];
    
    if Params.UseVel
        H = [1 0 0 0;...            % Measurement model - [X Vx Y Vy].'
             0 1 0 0;...
             0 0 1 0;...
             0 0 0 1];
    else
        H = [1 0 0 0;...            % Measurement model - [X Y].'
             0 0 1 0];
    end
elseif Params.ModelType == 1
    % Use velocities in the estimation process
    A      = [1 dt_extrap 0.5*dt_extrap^2;...
              0 1         dt_extrap;...
              0 0         1];
    
    Phi    = [A zeros(3);...        % Propagation model
              zeros(3) A];
    
    ATot   = [1 dT 0.5*dT^2;...
              0 1  dT;...
              0 0  1];
    
    PhiTot = [ATot zeros(3);...        % Propagation model
              zeros(3) ATot];
          
    if Params.UseVel
        H = [1 0 0 0 0 0;...             % Measurement model - [X Vx Y Vy].'
             0 1 0 0 0 0;...
             0 0 0 1 0 0;...
             0 0 0 0 1 0];
    else
        H = [1 0 0 0 0 0;...             % Measurement model - [X Y].'
             0 0 0 1 0 0];
    end
end

% Assign outputs
ParamsOut.A      = A;
ParamsOut.Phi    = Phi;
ParamsOut.ATot   = ATot;
ParamsOut.PhiTot = PhiTot;
ParamsOut.H      = H;








