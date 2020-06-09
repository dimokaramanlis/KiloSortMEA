function  readFrametimes(varargin)
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
[datafilenames, stimids, ismcd] = mcdormsrdh5(params.mcdatapath);
Nstimuli = max(stimids);

ops.madThres = params.madThres;
ops.plotint = params.PlotInt; ops.plotinclude = params.PlotInclude;
ops.Show = params.Show; ops.Save = params.Save;

for ii = 1:Nstimuli
    
    fprintf('Reading data for stimulus %d... ',ii); tic;
    stimfilenames = datafilenames(stimids == ii);
    %----------------------------------------------------------------------
    %get data
    datcell = cell(numel(stimfilenames), 1);
    for ifile = 1:numel(stimfilenames)
        if ismcd
            [datcell{ifile}, ops.fs] = readMCDanalongData(params.mcdatapath, stimfilenames{ifile});
        else
            [datcell{ifile}, ops.fs] = readH5analongData(params.mcdatapath, stimfilenames{ifile});
        end
    end
    stimdat = cell2mat(datcell);
    %----------------------------------------------------------------------
    % call frametimings
    [~,ops.filename,~] = fileparts(stimfilenames{1});
    newframetimings(stimdat, ops);
    %----------------------------------------------------------------------
    fprintf('Done! Took %.2f s\n',toc);
end

if ismcd; clear mexprog; end %unload DLL

end

%--------------------------------------------------------------------------------------------------%
%----------                               sub-functions                                  ----------%
%--------------------------------------------------------------------------------------------------%

function [outputfilenames, stimids, ismcd, mcddll] = mcdormsrdh5(dp)

mcdfilenames = dir([dp,filesep,'*.mcd']);

if isempty(mcdfilenames)
    datafilenames = dir([dp,filesep,'*.h5']);
    ismcd = false;
else
    ismcd = true;
    datafilenames = mcdfilenames;
end

if isempty(datafilenames)
    error('There aint no valid data shit in this folder, come at me with mcd or msrd-h5 format!');
end

[~, reindex] = sort(str2double(regexp(({datafilenames(:).name}),'\d+','match','once')));
outputfilenames = {datafilenames(reindex).name}';
stimids = zeros(numel(outputfilenames), 1);
for ifile = 1:numel(outputfilenames)
    sid = textscan(outputfilenames{ifile}, '%d_%s');
    stimids(ifile) = sid{1};
end

mcddll = [];
if ismcd %load the dll file
    [dllpath,libtoload] = getMCSdllPath();
    mcddll = mexprog(18, [dllpath, filesep, libtoload]);  %set dll library
end

end
%--------------------------------------------------------------------------------------------------%
function [mcddat, fs, stimsamples] = readMCDanalongData(dp, mcname)
mcdfile = fullfile(dp,mcname); %get mcd path
[~, hfile] = mexprog(1, mcdfile); %open file
[~, mcdfileInfo] = mexprog(3, hfile); %get file info
stimsamples = floor(mcdfileInfo.TimeSpan/mcdfileInfo.TimeStampResolution);
fs = round(1/mcdfileInfo.TimeStampResolution);

switch mcdfileInfo.EntityCount
    case 63; pulsechannel = 61;
    case 256; pulsechannel = 253;
end
[~,~,mcddat] = mexprog(8,hfile, pulsechannel-1,0,  stimsamples); %read data
nsresult = mexprog(14, hfile);%close mcd file
mcddat = single(mcddat);
end
%--------------------------------------------------------------------------------------------------%
function [mcddat, fs, stimsamples] = readH5analongData(dp, mcname)
h5file = fullfile(dp,mcname); %get h5 path
cfg = []; cfg.dataType = 'single';
stimdata = McsHDF5.McsData(h5file,cfg);

streamtype = cell(size(stimdata.Recording{1}.AnalogStream));
for ii = 1: size(stimdata.Recording{1}.AnalogStream,2)
    streamtype{ii} = stimdata.Recording{1}.AnalogStream{ii}.Label;
end
analogstream = ~(contains(streamtype,'Filter')); % get only the filtered stream

h5dat = stimdata.Recording{1}.AnalogStream{analogstream};
toVoltsFac = 10^double(h5dat.Info.Exponent(1));
mcddat = h5dat.ChannelData(1,:)*toVoltsFac;
fs = round(h5dat.getSamplingRate);
stimsamples = h5dat.ChannelDataTimeStamps(end);
end
%--------------------------------------------------------------------------------------------------%
