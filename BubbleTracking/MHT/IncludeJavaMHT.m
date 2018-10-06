%% Configuration
tracker_instalation_path = eval('pwd');

%% Add required files to java classpath
files= {
    'dist/lib/collections-generic-4.01.jar'
    'dist/lib/jaxb-api.jar'
    'dist/lib/jung-algorithms-2.0.jar'
    'dist/lib/jung-graph-impl-2.0.jar'
    'dist/lib/jung-visualization-2.0.jar'
    'dist/lib/junit-4.5.jar'
    'dist/lib/LisbonMHL-1.0.jar'
    'dist/lib/log4j-1.2.15.jar'
    'dist/lib/MHL2.jar'
    'dist/lib/Murty.jar'
    'dist/MatlabExampleApp.jar'};

for i = 1:length(files)
    eval(['javaaddpath ' tracker_instalation_path '/' files{i}]);
end

