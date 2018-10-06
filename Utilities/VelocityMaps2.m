function VelocityMaps2( Tracks, ImSize, Acq_Params, Tracker_Params, SR_params, varargin )
%VELOCITYMAPS Summary of this function goes here%
%
%
%
%

%% Initialization
% -------------------------------------------------------------------------
switch nargin
    case 6
        MIP   = varargin{1};
        IsSim = 0;
    case 7
        MIP   = varargin{1};
        IsSim = varargin{2};
    otherwise
        MIP   = [];
        IsSim = 0;
end

% I divide by 4 only since the images are already interpolated.
if IsSim % SIM
    SimFact  = 4; 1;
    WidthUse = 0.42;
    MaxVal_forDisp = 4; % Do not show outlier velocities, which are not physical
else % EXP
    SimFact  = 4;
    WidthUse = 0.4; 0.42; 
    MaxVal_forDisp = 4;
end

dX = Acq_Params.PixelSizes(1)/SR_params.SRF/SimFact; % [mm] - we divide by the SRF, since this is the actual size in the super-resolved image
dY = Acq_Params.PixelSizes(2)/SR_params.SRF/SimFact; % [mm]
dT = 1/Acq_Params.FrameRate;                 % [s]
dR = sqrt(dX^2 + dY^2);                      % [mm] - this is the diagonal length of each pixel

% Interpolation parameters
InterpFactor = 100;
InterpMethod = 'pchip';

% Generate axis 
FOV = [size(MIP, 1)*dY*SR_params.SRF, size(MIP, 2)*dX*SR_params.SRF];
x_vec = linspace(0, FOV(1), size(MIP, 1));
y_vec = linspace(0, FOV(2), size(MIP, 2));

MaxDisplayVel = MaxVal_forDisp; %  Upper limit for possible velocity display [mm/sec]
DR            = 30;             % [dB] dynamic range for the MIP image
MaxVel        = 0;              % Maximum velocity for display

%% Calculate average velocity magnitude and phase 
% -------------------------------------------------------------------------
% Calculate Magnitude and phase for each velocity point in each track
Tracks = CalcMagPhase(Tracks);

%figure(1431);
Width  = WidthUse; 0.42; 0.4;  0.7; % unitless
figure('units', 'normalized', 'outerposition', [0 0.05 0.7 0.7]); 
hold on;
% Display MIP image, if exists
if ~isempty(MIP)    
%     imagesc(x_vec, y_vec, MIP/max(MIP(:)));
    imagesc(x_vec, y_vec, db(MIP), [max(db(MIP(:)))-DR max(db(MIP(:)))]);
    set(gca, 'position', [0.2 0.2 Width Width]);

%     colormap((((0:2^10-1)/(2^10-1))'*[1 1 1]).^.4);
%     colormap(gray.^0.7);
    colormap(gray);
    freezeColors;
end

h = colorbar('EastOutside');
ylabel(h, '[mm/sec]');

% Overlay tracks on the image
for TrkCnt = 1:numel(Tracks)
    % Current track path and velocity - in physical measures
    Time   = Tracks{TrkCnt}.State(1, :);
    x      = Tracks{TrkCnt}.State(2, :)*dY;
    if size(Tracks{TrkCnt}.State, 1) == 7
        y  = Tracks{TrkCnt}.State(5, :)*dX;
    else
        y  = Tracks{TrkCnt}.State(4, :)*dX;
    end
%     VelMag = Tracks{TrkCnt}.VelMag*dR/dT/Tracker_Params.KF.Trate;
    VelMag = (Tracks{TrkCnt}.VelMag*dR)/dT;
    
    % For colorbar display
    MaxVel = max(MaxVel, max(VelMag(:)));
    
    % Perform interpolation - just for visualization
    [x, y, VelMag] = InterpData(Time, x, y, VelMag, InterpMethod, InterpFactor);
    y(end) = NaN;
    
    if max(VelMag(:)) < MaxDisplayVel   % [mm/sec]
%         plot(y, x, 'color', 'm');
%         FaceAlphaVal = max(VelMag(:))/MaxDisplayVel;
%         if max(VelMag(:)) < 0.2
%             FaceAlphaVal = 0;
%             LineWidthVal = 2;
%         else
%             FaceAlphaVal = 1;
%             LineWidthVal = 2; %2
%         end
        patch(y, x, VelMag, 'EdgeColor', 'interp', 'Marker', '.', 'MarkerFaceColor', 'flat', 'linewidth', 2);
    else
        disp('1');
    end
end
set(gca, 'ydir', 'reverse');
axis([0 ImSize(1)*dX 0 ImSize(2)*dY]);
%xlabel('[mm]');ylabel('[mm]');
set(gca, 'fontsize', 16);
set(gca, 'xtick', []);set(gca, 'ytick', []);
caxis([0 MaxDisplayVel]);

MaxVel

if ~isempty(MIP)  
    colormap(hot);
    cbfreeze(h);
end
% set(gca, 'xtick', []);set(gca, 'ytick', []);


%% Add scalebar
% -------------------------------------------------------------------------
% scalebar = [[1 1]*0.64 + [0 1]*Width/FOV(1)/2; [1 1]*0.23]; % I divide by 2 because of the 'axis square'
scalebar = [[1 1]*0.28 + [0 1]*Width/FOV(1)/2; [1 1]*0.22]; % I divide by 2 because of the 'axis square'
annotation(gcf, 'line', scalebar(1, :), scalebar(2, :), 'LineWidth', 3, 'Color', [1 1 1]);
% Create textbox
% annotation(gcf,'textbox', [0.633578313253012 0.294366817496229 9.98899999999914e-05 9.9999999999989e-05], 'Color',[1 1 1], 'EdgeColor', 'none', 'String',{'1\mum'}, 'fontsize', 20);
annotation(gcf,'textbox', [0.273222891566265 0.286183982505364 9.98899999999914e-05 9.9999999999989e-05], 'Color',[1 1 1], 'EdgeColor', 'none', 'String',{'1\mum'}, 'fontsize', 20);
axis square;

%% Auxiliary functions
% -------------------------------------------------------------------------
function Tracks = CalcMagPhase(Tracks_in)
Tracks = Tracks_in;
for TrkCnt = 1:numel(Tracks)
    if size(Tracks{TrkCnt}.State, 1) == 7
        % Velocity magnitude
        Tracks{TrkCnt}.VelMag    = sqrt(Tracks{TrkCnt}.State(3, :).^2 + Tracks{TrkCnt}.State(6, :).^2);   % [Time X Vx Ax Y Vy Ay]^T
        
        % Velocity orientation
        Tracks{TrkCnt}.VelOrient = atan(-Tracks{TrkCnt}.State(3, :)./Tracks{TrkCnt}.State(6, :))*180/pi;   % [deg]
    else
        % Velocity magnitude
        Tracks{TrkCnt}.VelMag    = sqrt(Tracks{TrkCnt}.State(3, :).^2 + Tracks{TrkCnt}.State(5, :).^2);   % [Time X Vx Y Vy]^T
        
        % Velocity orientation
        Tracks{TrkCnt}.VelOrient = atan(-Tracks{TrkCnt}.State(3, :)./Tracks{TrkCnt}.State(5, :))*180/pi;   % [deg]
    end
end

% 1D interpolation
function [x_interp, y_interp, vel_interp] = InterpData(Time, x, y, vel, method, InterpFactor)

% Interpolation time vector
InterpTime = linspace(Time(1), Time(end), length(Time)*InterpFactor);

% Perform interpolation
x_interp   = interp1(Time, x, InterpTime, method);
y_interp   = interp1(Time, y, InterpTime, method);
vel_interp = interp1(Time, vel, InterpTime, method);





















