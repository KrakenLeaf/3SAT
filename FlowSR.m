function [ SR_out, SR_out_reg, Tracks, ImagesBuffer, DetectedMB ] = FlowSR( MovieIn, PSF, SR_params, OF_params, Tracker_params )
%FLOWSR - Performs Super-resolution US imaging using a flow prior and
% optical flow estimation
%
%
%
%
%

global DEBUG VERBOSE VIDEO

if VERBOSE >= 1
   disp('Super-resolution Ultrasound imaging using SR flow estimation, V.1');
   disp('-----------------------------------------------------------------');
end

% -------------------------------------------------------------------------
%%                           Initialization
% -------------------------------------------------------------------------
% Size of the movie - assume the PSF has the same number pixels as the movie
[~, DimN, FrameNumber] = size(MovieIn);

% Super-resolution parameters
SRF          = SR_params.SRF;
SR_params.N  = (DimN*SRF)^2;
SR_out       = zeros(DimN*SRF, DimN*SRF, FrameNumber);
SR_out_reg   = SR_out;
CumulativeSR = zeros(DimN*SRF, DimN*SRF);

% Optical flow parameters
BurnIn      = OF_params.BurnIn;

% Prepare the PSF
[psfF, psfFdiag, ~] = psfPrepare(PSF);

% If recovery includes flow estimation
if SR_params.FlowFlag
    % Precalculations for OF estimation
    PreProc_OF        = OFestimator_Preprocess( OF_params );
    
    % MHT initialization
    Tracker           = MHT_init(Tracker_params);
    
    % Build the Kalman filter matrix model
    Tracker_params.KF = KalmanCreateMatrixModel( Tracker_params.KF );
    
    % Initialize the TrackManager cell array
    Tracks            = {};
    ID_list           = [];
end

% Initialize weighting matrix
Pw      = ones(size(psfF)*SR_params.SRF);
Pw_ones = Pw; % This is just an identity matrix - used only for comparison with non-weighted sparse recovery

% Precalculations for the SR recovery
if VERBOSE >= 1; disp('Pre-processing calculations'); end
if VERBOSE >= 1; disp('---------------------------'); end
[ S, L ] = pFISTA_precalc( psfFdiag, SR_params );

% Bubble state size
if Tracker_params.KF.ModelType == 1 
    % The state of each bubble is [X Vx Ax Y Vy Ay].'
    Tracker_params.KF.StateSize = 6;
else
    % The state of each bubble is [X Vx Y Vy].'
    Tracker_params.KF.StateSize = 4;
end

% Save images
ImagesBuffer = [];

% NUmber of detected MBs per frame
DetectedMB_stack     = [];
DetectedMB_stack_reg = [];

if VERBOSE >= 2; disp(['Solver type: ' SR_params.SolverType]); end
if VERBOSE >= 1; disp(' '); end
% -------------------------------------------------------------------------------------------------------------------------------------------------- %
%%                                                                          Main algorithm loop
% -------------------------------------------------------------------------------------------------------------------------------------------------- %
FrameCounter   = 1;
while FrameCounter <= FrameNumber
% while FrameCounter <= 10
    SingleRunTimer = tic;
    if VERBOSE >= 1; disp(['Frame ' num2str(FrameCounter) '/' num2str(FrameNumber) ':']); end
    if VERBOSE >= 1; disp(['------------------------------------------------------']); end
    
    % Perform sparse super-resolution recovery 
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    % Normalize current frame to values between 0-255
    CurrLR_frame = MovieIn(:, :, FrameCounter);
%     CurrLR_frame = CurrLR_frame/max(CurrLR_frame(:))*255;
    
    % Convert current frame to frequency domain - Assume square frames
    CurrFrameF         = fftshift((1/DimN^2)*fft2(CurrLR_frame));
    
    % Super-resolve current frame
    switch lower(SR_params.SolverType)
        case 'fista'
            TmpRec         = pFISTA_diag_US_3( CurrFrameF(:), psfFdiag, S, L, Pw, SR_params );
            TmpRec_regular = pFISTA_diag_US_3( CurrFrameF(:), psfFdiag, S, L, Pw_ones, SR_params );
        case 'fista_iterative'
            TmpRec         = pFISTA_Iterative_US( CurrFrameF(:), psfFdiag, S, L, Pw, SR_params );
            TmpRec_regular = pFISTA_Iterative_US( CurrFrameF(:), psfFdiag, S, L, Pw_ones, SR_params );
    end
    
%     DetectedMB_stack     = [DetectedMB_stack sum(TmpRec ~= 0)];
    DetectedMB_stack_reg = [DetectedMB_stack_reg sum(TmpRec_regular ~= 0)];
    
    % Reshape to image
    SuperResolvedFrame         = fftshift(real(reshape(TmpRec, sqrt(SR_params.N), sqrt(SR_params.N))));
    SuperResolvedFrame_reg     = fftshift(real(reshape(TmpRec_regular, sqrt(SR_params.N), sqrt(SR_params.N))));
    
    % SR stack
    SR_out(:, :, FrameCounter)         = SuperResolvedFrame;
    SR_out_reg(:, :, FrameCounter)     = SuperResolvedFrame_reg;
    
    % Cumulative SR image
    CumulativeSR         = CumulativeSR + SuperResolvedFrame;
    
    % Perform optical flow estimation of the super-resolved image
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if SR_params.FlowFlag && sum(SuperResolvedFrame(:) ~= 0)
        % Take a burn-in period of 'BurnIn' frames so it will be possible to estimate
        % the flow for the super-resolved images
        
        % Optional smoothing of the super-resolved frame, to produce smoother OF estimations
        if OF_params.UniformIntensity
            % Uniform intensity
            SR_sm = imbinarize(SuperResolvedFrame);
            
            % Optional smoothing
            h     = fspecial('Gaussian', 10*[1,1], 1);
            SR_sm = imfilter(double(SR_sm), h);
        else
            SR_sm = SuperResolvedFrame;
        end
        
        if FrameCounter >= BurnIn
            % From frame number 'BurnIn' forward we perform optical flow estimation and SR bubble tracking
            if VERBOSE >= 2;disp(['Performing optical flow estimation, with method: ' OF_params.Method]); end
%             [ OF ] = estimateFlow(PreProc_OF, double(CurrLR_frame));
            [ OF, OF_Interp ] = OFestimator( CurrLR_frame, PreProc_OF, OF_params, SR_params, Tracker_params.KF.dT);
            
            % Multi-hypothesis tracking algorithm - MHT 
            if VERBOSE >= 2;fprintf('Performing multiple hypothesis tracking, number of tracks: '); end
            [ Targets, DetectedMB_stack ] = MHT_track_frame( SR_sm, Tracker, DetectedMB_stack );
            
            % Manage tracks and associate velocities
            [ Tracks ] = TrackManager( Tracks, Targets, OF_Interp, size(SuperResolvedFrame), FrameCounter, Tracker_params.KF, FrameCounter );
            
            % NOTE: Weighting matrix is based on the state x_{n|n-1} (last column of the State matrix),  
            % that is, the propagated state before the Kalman update with the new measurement (which
            % haven't "arrived" yet). Similarly, the last CovP matrix is the P_{n|n-1} estimation
            % covariance matrix.
            
            % Calculate the weighting matrix
            Pw = SR_params.Eps*ones(size(SuperResolvedFrame));
            for TrkCnt = 1:numel(Tracks)
                Pw = Pw + Tracks{TrkCnt}.GMap;
            end
            Pw = 1./(Pw + SR_params.Eps);     % Eps is used to regulate small numbers so we won't get NaN
            
            % Normalize weights to range [0,1]
            Pw = Pw/max(Pw(:));
            
            if VERBOSE >= 2;disp(num2str(size(Targets, 1))); end
            
            if DEBUG == 1
%                 imshow(SR_sm, []);
%                 imagesc(imresize(CurrLR_frame, SRF*size(CurrLR_frame))); colormap hot;
                imagesc(uint8(CurrLR_frame)); colormap hot; title(['Frame #' num2str(FrameCounter) '/' num2str(FrameNumber)]);
                hold on;
                plot(OF, 'DecimationFactor', 1*[1 1], 'ScaleFactor', 25);
                hold off;
                drawnow;
            end
        end
    else
        % No tracking is performed
        Targets = [];
        
        % If not using flow
        if SR_params.FlowFlag == 0
           Tracks    = []; 
           OF_Interp = [];
        end
        if VERBOSE >= 2; disp(['FlowSR: No bubbles detected warning. lambda = ' num2str(SR_params.Lambda)]); end
    end
    
    if DEBUG == 2
        InternalDisplayFlag = 1; %1;
        if sum(SuperResolvedFrame(:) ~= 0)
            if InternalDisplayFlag == 1
                DisplayProcess(FrameCounter, SR_out_reg(:, :, 1:FrameCounter), MovieIn(:, :, 1:FrameCounter),...
                               SR_params.FlowFlag, Targets, Tracks, Tracker_params.KF.Trate, FrameCounter, OF_Interp);
%               DisplayProcess(FrameCounter, SR_out_regular(:, :, 1:FrameCounter), MovieIn(:, :, 1:FrameCounter),...
%                              SR_params.FlowFlag, Targets, Tracks, Tracker_params.KF.Trate, FrameCounter, OF_Interp);
            else
               DisplayMovieShort(FrameCounter, SR_out(:, :, 1:FrameCounter), MovieIn(:, :, 1:FrameCounter),... 
                                 Targets, Tracks, Tracker_params.KF.Trate, FrameCounter, OF_Interp); 
            end
        end
    end
    
    % Advance counter
    FrameCounter = FrameCounter + 1;
    if VERBOSE >= 2;toc(SingleRunTimer);end
end

% Output number of detected MBs
DetectedMB.Weighted    = DetectedMB_stack;
DetectedMB.NonWeighted = DetectedMB_stack_reg;

% -------------------------------------------------------------------------------------------------------------------------------------------------- %
%%                                                                          Auxiliary functions
% -------------------------------------------------------------------------------------------------------------------------------------------------- %
function [ psfF, psfFdiag, Nfactor ] = psfPrepare( PSF )
%PSFPREPARE - Convert PSF to frequency domain
N    = size(PSF, 1);                    % PSF is assumed to be square
psfF = fftshift((1/N^2)*fft2(PSF));

% Perform column normalization on A - for the sparse recovery algorithm
Nfactor = norm(psfF(:), 2);

% Diagonal matrix
% psfFdiag = diag(psfF(:)/Nfactor);
psfFdiag = spdiags(psfF(:)/Nfactor, 0, N^2, N^2);

function DisplayProcess(Index, SR_Frames, DL_Frames, FlowFlag, varargin)
persistent TrkFrame
global     VIDEO 

% find peaks above hard threshold..
Ohat = SR_Frames(:, :, Index);
T = 0.2;
[r,c] = find(Ohat > T);
% Ohat(Ohat <= T) = 0;

Tracks       = varargin{2};
Trate        = varargin{3};
FrameCounter = varargin{4};
OF           = varargin{5};

NumTracks    = numel(Tracks);

% Subplots positions
pos  = [0.06 0.46 0.2 0.6]; % [0.05 0.6 0.2 0.32];
xpos = [.201 0 0 0]; % [.175 0 0 0];
ypos = [0 -.4103 0 0]; % [0 -.35 0 0];

h = fspecial('Gaussian',10*[1,1],1);

i_inter = 1;           % show plot every "i_inter" frames
if mod(Index, i_inter) == 0
    FigRef = 4; figure(FigRef);
    set(FigRef, 'units', 'normalized', 'outerposition', [0 .05 0.95 .95])
    
    % MIP - Maximum Intensity Projection
    subplot(2,3,1)
    imagesc(max(DL_Frames, [], 3)); 
    title('MIP', 'color', 'g');set(gca, 'xtick', []);set(gca, 'ytick', []);
%     set(gca,'Position',pos + xpos*1)
    
    % Last DL frame
    subplot(2,3,2)
    imagesc(imresize(DL_Frames(:, :, Index), size(Ohat)));  %caxis([0,30])
    % Display also the optical flow estimation
    if ~isempty(OF)
        hold on;
        plot(OF, 'DecimationFactor', 3*[1 1], 'ScaleFactor', 25);
        hold off;
        drawnow;
    end
    % Plot markers for detected positions
    hold on; plot(c,r,'x','MarkerSize',10,'LineWidth',1,'color',[0,1,0]);
    title(['DL frame #' num2str(FrameCounter)], 'color', 'g');set(gca, 'xtick', []);set(gca, 'ytick', []);
    hold off;
%     set(gca,'Position',pos + xpos*2)
    
    % Last SR frame
    subplot(2,3,3)
    imagesc(SR_Frames(:, :, Index)); %caxis([0,1])
    title('Raw localizations', 'color', 'g');set(gca, 'xtick', []);set(gca, 'ytick', []);
%     set(gca,'Position',pos + xpos*3)
    
    % Accumulation of smoothed SR frames
    subplot(2,3,4)
    imagesc(imfilter(sum(SR_Frames, 3), h).^0.75); %caxis([0,1]); % Temporal mean
%     imagesc(imfilter(max(SR_Frames, [], 3), h).^0.75); %caxis([0,1]); % MIP
    title('Smoothed SR', 'color', 'g');set(gca, 'xtick', []);set(gca, 'ytick', []);
%     set(gca,'Position',pos + xpos*1 + ypos)
    
    % State estimation
    subplot(2,3,5);
    if ~isempty(Tracks) 
        if FrameCounter == 1
            TrkFrame = zeros(size(Ohat));
        end
        
        for jj = 1:NumTracks
%             Inds       = find(floor(Tracks{jj}.State(1, :)) == FrameCounter);
            Lsize = length(Tracks{jj}.State(1, :));
            Inds = (Lsize - Trate):Lsize;
            if size(Tracks{jj}.State, 1) == 7
                Points = [Tracks{jj}.State(2, Inds); Tracks{jj}.State(5, Inds)]; % [Time X Vx Ax Y Vy Ay]
            else
                Points = [Tracks{jj}.State(2, Inds); Tracks{jj}.State(4, Inds)]; % [Time X Vx Y Vy]
            end
            TrkFrame   = TrkFrame + CreateImageFromPoints(TrkFrame, Points, size(Ohat)); % Temporal mean
%             TrkFrame   = max(reshape( [TrkFrame; CreateImageFromPoints(TrkFrame, Points, size(Ohat))], [size(TrkFrame) 2]), [], 3); % MIP
        end
        imagesc(imfilter(double(imbinarize(TrkFrame)), h).^0.75); caxis([0,1]);
    else
        imagesc(zeros(10, 10));
    end
    title('Smoothed state est.', 'color', 'g');set(gca, 'xtick', []);set(gca, 'ytick', []);
%     set(gca,'Position',pos + xpos*2 + ypos)
    
    % SR frame smoothed
    subplot(2,3,6);
    imagesc(imfilter(SR_Frames(:, :, Index), h).^0.75); caxis([0,1]);
%     set(gca,'Position',pos + xpos*3 + ypos)
    
    % Plot tracking numbers
    if FlowFlag
        hold on;
        Targets = varargin{1};
        plot(Targets(:, 1), Targets(:, 2), 'g*');
        hold off;
        
        use_blob_colors = false;
        if sum(size(Targets)>0)==2
            for j = 1:size(Targets, 1)
                textprops = '\fontsize{16}';
                if use_blob_colors
                    textprops = [textprops ' \color[rgb]{' getColor(Targets(j, 4)) '}'];
                else
                    textprops = [textprops ' \color{green}'];
                end
                text(Targets(j, 1), Targets(j, 2), [textprops sprintf(' %d',Targets(j, 3))]);
            end
        end
    end
    title('SR locs with IDs', 'color', 'g');set(gca, 'xtick', []);set(gca, 'ytick', []);
    
    % Draw
    colormap('hot')
    set(gcf, 'color', 0.2*[1 1 1])
    drawnow;
    
    % Capture the frame
    if VIDEO ~= -1; writeVideo(VIDEO, getframe(FigRef));end;
end

function TrkFrame = CreateImageFromPoints(TrkFrameIn, Points, SizeFrame)
% Initialize empty image
TrkFrame = TrkFrameIn;

% Points is the XY coordinates of a single track [X; Y]
PointsRound = round(Points);

% Find out of bounds indices and discard them
IndsTmpX    = find(PointsRound(1,:).' >= 1 & PointsRound(1,:).' <= SizeFrame(1));
IndsTmpY    = find(PointsRound(2,:).' >= 1 & PointsRound(2,:).' <= SizeFrame(2));
[C, IX, IY] = intersect(IndsTmpX, IndsTmpY);

% Put 1's where there is a point emitter
try
    % This is the original line - catch is only for debug. Should be deleted later on
    Inds = sub2ind(size(TrkFrame), PointsRound(1,IX).', PointsRound(2, IY).');
    TrkFrame(Inds) = 1;
catch
    %IX
    %IY
    %PointsRound(1,IX)
    %PointsRound(2, IY)
    %size(TrkFrame)
%     waitforbuttonpress
end


function DisplayMovieShort(Index, SR_Frames, DL_Frames, varargin)
persistent TrkFrame
global     VIDEO 

% find peaks above hard threshold..
Ohat = SR_Frames(:, :, Index);
T = 0.2;
[r,c] = find(Ohat > T);
% Ohat(Ohat <= T) = 0;

Tracks       = varargin{2};
Trate        = varargin{3};
FrameCounter = varargin{4};
OF           = varargin{5};

NumTracks    = numel(Tracks);

% Subplots positions
pos  = [0.06 0.46 0.2 0.6]; % [0.05 0.6 0.2 0.32];
xpos = [.201 0 0 0]; % [.175 0 0 0];
ypos = [0 -.4103 0 0]; % [0 -.35 0 0];

h = fspecial('Gaussian',10*[1,1],1);

i_inter = 1;           % show plot every "i_inter" frames
if mod(Index, i_inter) == 0
    FigRef = 4; figure(FigRef);
    set(FigRef, 'units', 'normalized', 'outerposition', [0 .05 0.95 .95])
    
    % MIP - Maximum Intensity Projection
    subplot(1,2,1)
    imagesc(max(DL_Frames, [], 3)); 
    title(['MIP, frame ' num2str(Index)], 'color', 'g');set(gca, 'xtick', []);set(gca, 'ytick', []);axis square;
%     set(gca,'Position',pos + xpos*1)

    % State estimation
    subplot(1,2,2);
    if ~isempty(Tracks) 
        if FrameCounter == 1
            TrkFrame = zeros(size(Ohat));
        end
        
        for jj = 1:NumTracks
            Inds       = find(floor(Tracks{jj}.State(1, :)) == FrameCounter);
            if size(Tracks{jj}.State, 1) == 7
                Points = [Tracks{jj}.State(2, Inds); Tracks{jj}.State(5, Inds)]; % [Time X Vx Ax Y Vy Ay]
            else
                Points = [Tracks{jj}.State(2, Inds); Tracks{jj}.State(4, Inds)]; % [Time X Vx Y Vy]
            end
            TrkFrame   = TrkFrame + CreateImageFromPoints(TrkFrame, Points, size(Ohat)); % Temporal mean
%             TrkFrame   = max(reshape( [TrkFrame; CreateImageFromPoints(TrkFrame, Points, size(Ohat))], [size(TrkFrame) 2]), [], 3); % MIP
        end
        imagesc(imfilter(double(imbinarize(TrkFrame)), h).^0.75); caxis([0,1]);
    else
        imagesc(zeros(10, 10));
    end
    title(['Trajectories, frame ' num2str(Index)], 'color', 'g');set(gca, 'xtick', []);set(gca, 'ytick', []);axis square;
%     set(gca,'Position',pos + xpos*2 + ypos)

    % Draw
    colormap('hot')
    set(gcf, 'color', 0.2*[1 1 1])
    drawnow;
    
    % Capture the frame
    if VIDEO ~= -1; writeVideo(VIDEO, getframe(FigRef));end;
end






















