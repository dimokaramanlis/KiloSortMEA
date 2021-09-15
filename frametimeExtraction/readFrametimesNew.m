function  readFrametimesNew(varargin)
%READFRAMETIMES Summary of this function goes here

% This function reads the frametimes directly from mcd or msrd file and
% feed them to the new frametimings function. Using this, there is no need
% for data conversion to bin format and the output is tidy.
%
%================================Inputs====================================
%
%   mcdatapath : folder path to the mcd or msrd-h5 file.
%   pulsechannel : channel number that has the pulse data.
%   Show : option to plot figure.
%   Save : option to save the output file as mat.
%   ShapeOffset : pulse shape offset, changes by amplifier.
%   SignalThresh : signal threshold, changes by amplifier.
%   PulseThresh : pulse baseline threshold.
%   MaxHeight : maximum pulse height.
%   Baseline :general baseline value.
%   MSecTick : some bullshit way that mcdata is stored, in 0.1 msec.
%   Nblink : value to define onset and off of pulses. Set to 1 if you want
%            to get both onset and offset of each pulse. Otherwise only for stimuli
%            that have the word 1 blink in their name the pulses are extracted
%            whenever the stimuli is changing.
%   SaveFigFormat : option to save the output figure as .fig.
%   OverwriteCriticalParameters : option to overwrite critical values. I
%                                 would not use it if I were you.
%
%================================Output====================================
%
%   frametime : pulses per stimuli change.
%
% written by Mohammad, 07.10.2019, as part of Kilosort functions.

% parse input
p = inputParser();
p.addParameter('mcdatapath', [], @(x) ischar(x));
p.addParameter('Show', true, @(x) islogical(x));
p.addParameter('Save', true, @(x) islogical(x));
p.addParameter('PlotInt', .4e-3, @(x) isnumeric(x));  %in seconds
p.addParameter('PlotInclude', 15, @(x) isnumeric(x)); %in seconds
p.addParameter('madThres', 30, @(x) isnumeric(x));
p.addParameter('SaveFigFormat', false, @(x) islogical(x));
p.addParameter('fs', 25e3, @(x) isnumeric(x));
p.addParameter('convfac', 0.125, @(x) isnumeric(x));
p.addParameter('Nchan', 252, @(x) isnumeric(x));
p.CaseSensitive = false; % make it case-insensitive

p.parse(varargin{:});
params = p.Results;

if isempty(params.mcdatapath) || ~exist(params.mcdatapath,'dir')
    params.mcdatapath = uigetdir([],'Select mc data folder');
end

% make output folder
ftfolder = fullfile(params.mcdatapath, 'frametimes');
if ~exist(ftfolder,'dir'), mkdir(ftfolder); end
ops.exportpath = ftfolder;

% get the data format
[datafilenames, stimids] = mcdormsrdh5(params.mcdatapath);
Nstimuli = max(stimids);

ops.madThres = params.madThres;
ops.plotint = params.PlotInt; ops.plotinclude = params.PlotInclude;
ops.Show = params.Show; ops.Save = params.Save;
ops.fs   = params.fs;

analogpath = fullfile(params.mcdatapath, 'ks_sorted', 'analog');
Nanalog    = 4;
if params.Nchan < 200
    Nanalog = 3;
end

for ii = 1:Nstimuli
    
    fprintf('Reading data for stimulus %d... ',ii); tic;
    stimfilename = datafilenames{stimids == ii};
    %----------------------------------------------------------------------
    %get data
    fid = fopen(fullfile(analogpath, stimfilename), 'r');
    datall = fread(fid, [Nanalog Inf], 'int16');
    fclose(fid);
    analogdat = params.convfac * double(datall(1,:)) * 1e-3;
    %----------------------------------------------------------------------
    % call frametimings
    [~,ops.filename,~] = fileparts(stimfilename);
    newframetimings(analogdat, ops);
    %----------------------------------------------------------------------
    fprintf('Done! Took %.2f s\n',toc);
end


end

%--------------------------------------------------------------------------------------------------%
%----------                               sub-functions                                  ----------%
%--------------------------------------------------------------------------------------------------%

function [outputfilenames, stimids] = mcdormsrdh5(dp)


analogpath = fullfile(dp, 'ks_sorted', 'analog');
filenames = dir([analogpath, filesep,'*.dat']);

if isempty(filenames)
    error('There are no valid data in this folder, try the conversion again.');
end

[~, reindex] = sort(str2double(regexp(({filenames(:).name}),'\d+','match','once')));
outputfilenames = {filenames(reindex).name}';
stimids = zeros(numel(outputfilenames), 1);
for ifile = 1:numel(outputfilenames)
    sid = textscan(outputfilenames{ifile}, '%d_%s');
    stimids(ifile) = sid{1};
end



end
