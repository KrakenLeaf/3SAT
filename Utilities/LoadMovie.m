function [ MovieOut, psfOut ] = LoadMovie( InFolder, InputName, DataType )
%LOADMOVIE - Load input DL movie for the FlowSR recovery method
%            and do some required processing
%
% Syntax:
% -------
% [ MovieOut, psfOut ] = LoadMovie( InFolder, InputName, DataType )
%
% Inputs:
% -------
% InFolder  - name of the folder in which the movie is located
% InputName - Name of the movie
% DataType  - Type of the input. Currently supported types:
%             'mat' - Matlab mat file. Assumed to be a struct with fields
%             'dl' and 'psf'
%

% Initialization
MovieOut = [];
psfOut   = [];

% Determine data type
switch lower(DataType)
    % Data file is a 'MAT' file - assumed to be a struct which contains all
    % the relevant data
    case 'mat'
        % Load data
        Tmp    = load(fullfile(InFolder, InputName));
        stName = fieldnames(Tmp);
        
        % Extract the movie - assume that the input is a struct with the field 'dl' or 'DL'
        try
            TmpCommand  = char(['MovieOut = getfield(Tmp.' stName ', ''dl'');']).';
            TmpCommand2 = reshape(TmpCommand, [1 size(TmpCommand, 1)*size(TmpCommand, 2)]);
            eval(TmpCommand2);
        catch
            TmpCommand  = char(['MovieOut = getfield(Tmp.' stName ', ''DL'');']).';
            TmpCommand2 = reshape(TmpCommand, [1 size(TmpCommand, 1)*size(TmpCommand, 2)]);
            eval(TmpCommand2);
        end
        
        clear TmpCommand TmpCommand2
        % Assume the loaded struct has also a 'PSF' / 'psf' field
        try
            TmpCommand  = char(['psfOut = getfield(Tmp.' stName ', ''psf'');']).';
            TmpCommand2 = reshape(TmpCommand, [1 size(TmpCommand, 1)*size(TmpCommand, 2)]);
            eval(TmpCommand2);
        catch
            TmpCommand  = char(['psfOut = getfield(Tmp.' stName ', ''PSF'');']).';
            TmpCommand2 = reshape(TmpCommand, [1 size(TmpCommand, 1)*size(TmpCommand, 2)]);
            eval(TmpCommand2);
        end
    otherwise
        error('LoadMovie: File type not supported.');
end














