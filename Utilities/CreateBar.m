clc;
close all;
clear;

% openfig('Pw_map2.fig');
openfig('Locs.fig');

width = 0.55;

set(gcf, 'units', 'normalized', 'outerposition', [0.1 0.1 width width]);

SRF = 4;
pixelSize = 0.146; %[mm] - size of pixel in the low-resolution image
NumPixels = 64; % # pixels of the low-resolution image

FOV = pixelSize*NumPixels; % [mm]

x_grid = linspace(0, FOV, NumPixels*SRF);

scalebar = [[1 1]*0.4 + [0 1]*width/FOV; [1 1]*0.23];

figure('units', 'normalized', 'outerposition', [0.1 0.1 width width]);
imagesc(x_grid, x_grid, ones(NumPixels*SRF)); axis square;
%set(gca, 'xtick', []);set(gca, 'ytick', []);
set(gca, 'xtick', [0 1 2 3 4 5 6 7 8 9]);

%annotation(gcf, 'line', scalebar(1, :), scalebar(2, :), 'Linewidth', 3, 'Color', 0*[1 1 1]);
annotation(gcf,'line',[0.42415458937198 0.464975845410628],...
    [0.237832898172324 0.237597911227154],'LineWidth',3);
annotation(gcf,'textbox',...
    [0.38647342995169 0.218321151470702 0.104468596280341 0.114882503881778],...
    'String',{'1mm'},...
    'LineStyle','none',...
    'FontSize',20);











