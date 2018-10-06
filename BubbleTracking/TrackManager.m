function [ TrackingCell_out ] = TrackManager( TrackingCell_in, Targets, Flow, ImageSize, FrameCounter, KF_Params, FirstTimeFlag )
%TRACKMANAGER - This script manages all the tracking procedure of the different
% bubbles which are detected in the frames. It opens new tracks and closes old
% ones and invokes the Kalman filtering procedure
%
%
%
% Inputs:
% -------
% TrackingCell_in - Cell array. In each cell are all the tracking data of a
%                   single super-resolved bubble
% SR_frame        - Current super-resolved frame
%
%

%% Initialization
% ------------------------------------------------------------------------------
% Counter for existing tracks' IDs
persistent UsedTrkID

% Determine number of monitored tracks
nTrk    = length(TrackingCell_in);

% Number of possible new tracks
nNewTrk = size(Targets, 1);

% New Targets array (TargetsWithVel) - Time X Vx Y Vy Flow_Magnitude Flow_Orientation ID
TargetsWithVel       = zeros(nNewTrk, 8);
TargetsWithVel(:, 1) = FrameCounter;        % Time
TargetsWithVel(:, 2) = Targets(:, 2);       % X
TargetsWithVel(:, 4) = Targets(:, 1);       % Y
TargetsWithVel(:, 8) = Targets(:, 3);       % Track ID

StateSize = KF_Params.StateSize;

%% Step 1: Associate velocities to Targets
% ------------------------------------------------------------------------------
% Format of Targets: X Y ID ? (X from left to right, Y from top to bottom)
Inds       = round(Targets(:, 1:2));
LinearInds = sub2ind(ImageSize, Inds(:, 2), Inds(:, 1));
for ii = 1:size(Inds, 1)
    TargetsWithVel(ii, 3) = Flow.Vx(LinearInds(ii));             % Vx
    TargetsWithVel(ii, 5) = Flow.Vy(LinearInds(ii));             % Vy 
    TargetsWithVel(ii, 6) = Flow.Magnitude(LinearInds(ii));      % Flow magnitude
    TargetsWithVel(ii, 7) = Flow.Orientation(LinearInds(ii));    % Flow orientation
end

% Assign mew measurements to TrackingCell_out according to track ID
Template.ID          = [];  % Track ID
Template.Measurement = [];  % Measurement
Template.State       = [];  % Track state - [Time X Vx Ax Y Vy Ay]
Template.CovP        = [];  % State covariance matrix

if FirstTimeFlag == 1   % First time in the loop
    UsedTrkID = [];
    TrackingCell_out = {};
    for ii = 1:nNewTrk
        TrackingCell_out = InitCell(TrackingCell_out, ii, Template, TargetsWithVel(ii, :), StateSize);
    end
else
    % Naive implementation - find which tracks are new and which should be updated
    TrackingCell_out = TrackingCell_in;
    
    % We use CellID just for convenience
    CellID = zeros(numel(TrackingCell_out));
    for ii = 1:nTrk
        % Create intersection of the two indices groups
        CellID(ii) = TrackingCell_out{ii}.ID;            % Ordered according to the cell indices
    end
    % Find tracks with new measurements
    InTrks = ismember(CellID, TargetsWithVel(:, 8));
    
%     UsedTrkID = [];
    for jj = 1:length(InTrks)
        if InTrks(jj) == 1
            IndUp = find(TrackingCell_out{jj}.ID == TargetsWithVel(:, 8));
            
            % Update existing tracks
            TrackingCell_out{jj}.Measurement = [TrackingCell_out{jj}.Measurement TargetsWithVel(IndUp, 1:7).'];
            TrackingCell_out{jj}.NewMeasFlag = 1; % Indicates that a new measurement has arrived for current track
            
            % Mark this new update as used
            UsedTrkID = unique([UsedTrkID; TargetsWithVel(IndUp, 8)]);
        end
    end
    
    % Create new tracks - measurements which were not used before
    NewTrksInds = ismember(TargetsWithVel(:, 8), UsedTrkID);
    
    TotNumTracks = numel(TrackingCell_out);
    for kk = 1:length(NewTrksInds)
        % Found a new track
        if NewTrksInds(kk) == 0
            TrackingCell_out = InitCell(TrackingCell_out, TotNumTracks + 1, Template, TargetsWithVel(kk, :), StateSize);       
            TotNumTracks = TotNumTracks + 1;
        end
    end
end

%% Step 2: Update tracks by applying Kalman filtering
% ------------------------------------------------------------------------------
% For each track - update its state and extimated covariance matrix
TotNumTracks = numel(TrackingCell_out);                     % Number of tracks in total
for TrackInd = 1:TotNumTracks
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % NOE: Track update is performed only for tracks with new meaurements. 
    % If new measurement has arrived, then the track is closed and  won't 
    % be updated any longer. This prevents infinite state extrapolation
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if TrackingCell_out{TrackInd}.NewMeasFlag
        % Arrange inputs properly
        PrevState = TrackingCell_out{TrackInd}.State(:, end);         % Last state
        if KF_Params.UseVel
            % Use estimated velocities 
            Mes   = TrackingCell_out{TrackInd}.Measurement(2:5, end); % Last measurement - only [X Vx Y Vy].'
        else
            % Do not use estimated velocities - [X Y]
            Mes   = [TrackingCell_out{TrackInd}.Measurement(2, end) TrackingCell_out{TrackInd}.Measurement(4, end)].';
        end
        
        % Covariance matrices 
        % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % NOTE: Model and measurement covariance matrices are inside the
        % loop, since in theory they can be changed from time to time
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Estimation covariance matrix
        % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        P = reshape( TrackingCell_out{TrackInd}.CovP(:, end), [StateSize StateSize] ); % Last estimated covariance matrix
       
        InternalFlag = 0;
        if InternalFlag
            % Model covariance matrix
            % ~~~~~~~~~~~~~~~~~~~~~~~
            if StateSize == 6
                %            Q = diag([.1 1 1e6 .1 1 1e6]);              % [X Vx Ax Y Vy Ay]
                Q = diag([.001 .0001 .001 .001 .0001 .001]);              % [X Vx Ax Y Vy Ay]
                %            Q = diag(1e1*[1 1 1 1 1 1]);  % Just for demo purposes - do not use!
            else
                Q = diag([.1 1 .1 1]);                      % [X Vx Y Vy]
            end
            % Q = 1*eye(StateSize, StateSize);
            
            % Measurement covariance matrix
            % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            if length(Mes) == 4
                R = diag([0.1 1 0.1 1]); % [X Vx Y Vy]
            else
                R = diag(0.01*[1 1]); % [X Y]
            end
        else
            % Model covariance matrix
            % ~~~~~~~~~~~~~~~~~~~~~~~
            %Q = KF_Params.Q;
            Q = GenerateQ(StateSize, KF_Params); 
            
            % Measurement covariance matrix
            % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            R = KF_Params.R;
        end
        % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        
        % Invoke the Kalman filter for each track
        % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        if size(TrackingCell_out{TrackInd}.State, 2) == 1
            % If state is only the initial state - perform only prediction
            [ EstState, P_out ] = KalmanPropagator( PrevState, P, Q, KF_Params );
        else
            % If we have a new measurement - update last state and then perform prediction
            [ EstStateup, Pup ]                      = KalmanFlow( PrevState, Mes, P, Q, R, KF_Params ); % !!!!!!!!!!!!!!
            TrackingCell_out{TrackInd}.State(:, end) = EstStateup;
            
            % Propagation
            [ EstState, P_out ] = KalmanPropagator( EstStateup, Pup, Q, KF_Params );
        end
        
        % Create a Gaussian based on the last covariance for the weighting matrix
%         GaussianMap = [];       % Only temporary
        if StateSize == 6
            GaussianMap = DrawCovGauss( [EstState(5, end); EstState(2, end)],...
                          vec([P_out(1, 1) P_out(1, 4); P_out(4, 1) P_out(4, 4)]), ImageSize );
        else
            GaussianMap = DrawCovGauss( [EstState(4, end); EstState(2, end)],...
                          vec([P_out(1, 1) P_out(1, 3); P_out(3, 1) P_out(3, 3)]), ImageSize );
        end
        
        % Arrange outputs properly
        TrackingCell_out{TrackInd}.State       = [TrackingCell_out{TrackInd}.State EstState];
        TrackingCell_out{TrackInd}.CovP        = [TrackingCell_out{TrackInd}.CovP  vec(P_out)];
        TrackingCell_out{TrackInd}.GMap        = GaussianMap;
        
        TrackingCell_out{TrackInd}.NewMeasFlag = 0; % No new measurements - this is used to close old tracks which have no additional measurements
    end
end

%% Auxiliary functions
% ------------------------------------------------------------------------------
function y = vec(x)
y = x(:);

function Cell_out = InitCell(Cell_in, ii, Template, TargetsWithVel, StateSize)
% TargetsWithVel - Time X Vx Y Vy Flow_Magnitude Flow_Orientation ID
% Initial template
Cell_in{ii} = Template;

Cell_in{ii}.ID          = TargetsWithVel(1, 8);           % New track ID
Cell_in{ii}.Measurement = TargetsWithVel(1, 1:7).';       % New measurement [Time X Vx Y Vy Flow_Magnitude Flow_Orientation]

if StateSize == 6
    % The state of each bubble is [Time X Vx Ax Y Vy Ay].'
    Cell_in{ii}.State   = [TargetsWithVel(1, 1),...
                           TargetsWithVel(1, 2:3), 0,...
                           TargetsWithVel(1, 4:5), 0].';  % Initialize track state - [Time X Vx 0 Y Vy 0]
else
    % The state of each bubble is [Time X Vx Y Vy].'
    Cell_in{ii}.State   = TargetsWithVel(1, 1:5).';       % Initialize track state - [Time X Vx Y Vy]
end

Cell_in{ii}.CovP        = zeros(StateSize^2, 1);          % State covariance matrix
Cell_in{ii}.GMap        = [];                             % Palce-holder for creating the weighting matrix
Cell_in{ii}.NewMeasFlag = 1;                              % Indicates that we have a new measurement

% Output
Cell_out = Cell_in;

function Q = GenerateQ(StateSize, KF_Params)
T   = KF_Params.dT;
rho = KF_Params.rho;

% Generate the Q matrix
if StateSize == 6
    % Continuous Wiener process acceleration
    Q = [ 1/20*T^5, 1/8*T^4, 1/6*T^3;...
          1/8*T^4, 1/3*T^3, 1/2*T^2;...
          1/6*T^3, 1/2*T^2, T];
      
    % Discrete white noise acceleration model
%     Q = [ 1/4*T^4, 1/2*T^3, 1/2*T^2;...
%           1/2*T^3, T^2, T;...
%           1/2*T^2, T, 1];
else % [X Vx Y Vy]
    % Continuous Wiener process acceleration
	Q = [ 1/3*T^3, 1/2*T^2; ...
          1/2*T^2, T];
      
    % Discrete white noise acceleration model
%     Q = [ 1/4*T^4, 1/2*T^3; ...
%           1/2*T^3, T^2];
end

Q = [Q zeros(StateSize/2, StateSize/2); zeros(StateSize/2, StateSize/2) Q]*rho;
































