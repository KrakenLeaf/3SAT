clc;
clear;
% close all;

%% Load data
% -------------------------------------------------------------------------
figure('units', 'normalized', 'outerposition', [0 0.05 0.7 0.7]); 
MaxRuns = 1;
for jj = 1:MaxRuns
    DataSet = jj;
    switch DataSet
        case 1 %%%% GOOD result - USE
            % Exp data Trate = 100
            DataFolder = 'Results\Results_07-Mar-2018';
            DataName   = 'Output_07_Mar_2018_09_35_26';
            
            InputConfigFile = 'ConfigFile_sim_1_07_Mar_2018_09_35_26.txt';
            MaxDispVel = 0.4; % m/s
            RunTitle   = 'Simulation 1';
    end
    
    load(fullfile(DataFolder, DataName));
    [ MovieFolder, InputName, DataType, SaveFolder, General_Params, Acq_Params, Tracker_Params, OF_params, SR_params ] = ReadConfigFile( fullfile(DataFolder, InputConfigFile) );
    
    Tracker_Params.KF.Trate
    Tracker_Params.KF.dT
         
    dX = Acq_Params.PixelSizes(1)/SR_params.SRF; % [mm] - we divide by the SRF, since this is the actual size in the super-resolved image
    dY = Acq_Params.PixelSizes(2)/SR_params.SRF; % [mm]
    dT = 1/Acq_Params.FrameRate;                 % [s]
    dR = sqrt(dX^2 + dY^2);                      % [mm] - this is the diagonal length of each pixel
    
    Trate = Tracker_Params.KF.Trate;
    
    %% Generate velocities histogram from the tracks
    % -------------------------------------------------------------------------
    VelVec      = [];
    AccVec      = [];
    NumericVels = [];
    for ii = 1:numel(Tracks)
        if length(Tracks{1}.State(:, 1)) == 7
            TmpVels = sqrt((Tracks{ii}.State(3, Trate + 1:end)).^2 + (Tracks{ii}.State(6, Trate + 1:end)).^2);
            TmpAccs = sqrt((Tracks{ii}.State(4, Trate + 1:end)).^2 + (Tracks{ii}.State(7, Trate + 1:end)).^2);
        else
            TmpVels = sqrt((Tracks{ii}.State(3, Trate + 1:end)).^2 + (Tracks{ii}.State(5, Trate + 1:end)).^2);
        end

        TmpNumeric = sqrt((diff(Tracks{ii}.State(2, Trate + 1:end))).^2 + (diff(Tracks{ii}.State(5, Trate + 1:end))).^2);
        
        % Accumulate
%         if jj == 2 || jj == 4
            VelVec = [VelVec; (TmpVels(:)*dR)/dT];
%             AccVec = [AccVec; TmpAccs(:)*dR/(dT)^2];
%         else
%             VelVec = [VelVec; TmpVels(:)*dR/(dT/Trate)];
%             AccVec = [AccVec; TmpAccs(:)*dR/(dT)^2];
%         ensd
        NumericVels = [NumericVels; TmpNumeric(:)*dR/(dT/Trate)];
    end
    
    Nbins = 100;
    subplot(1, MaxRuns, jj);
    h = histogram(VelVec(1:Trate:end), Nbins);
%     h = histogram(NumericVels(1:Trate:end), Nbins);
    xlabel('Velocity [mm/s]');
    set(gca, 'fontsize', 20);
    %axis([0 MaxDispVel 0 max(h.Values)]);
    title(RunTitle);
    
    max(VelVec)
    
    axis square;
%     figure;
%     histogram(AccVec(1:Trate:end), Nbins);
end

% %% Add letters
% % -------------------------------------------------------------------------
% str   = 'abc';
% xpos  = [0.281 0 0 0]; 
% ypos  = [0 -(0.3+0.01) 0 0]; 
% posa  = [0.305275286018021 0.656612979102106 0.0302303592917311 0.0779411073731031];
% ixpos = [0:2 0:2];
% iypos = [0 0 0 1 1 1];
% 
% for qq = 1:MaxRuns
%     % Letter
%     annotation('textbox',...
%         posa+ixpos(qq)*xpos+iypos(qq)*ypos,...
%         'String',{['(' str(qq) ')']},...
%         'FontSize',24,...
%         'FontName','Calibri',...
%         'FitBoxToText','off',...
%         'EdgeColor','none',...
%         'Color',0*[1 1 1]);
% end
% 

% figure;
% Vvec = VelVec(1:Tracker_Params.KF.Trate:end);
% Avec = AccVec(1:Tracker_Params.KF.Trate:end);
% Inds = find(Avec < 1e5);
% histogram2(Vvec(Inds), Avec(Inds), Nbins);
% xlabel('Velocity [m/s]');ylabel('Acceleration [m/s^2]');






