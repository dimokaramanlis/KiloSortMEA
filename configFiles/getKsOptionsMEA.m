function [ops] = getKsOptionsMEA(metadata)
%GETKSOPTIONSMEA Summary of this function goes here
%   Detailed explanation goes here

%==========================================================================
% main processing options
ops.GPU                 = 1; % whether to run this code on an Nvidia GPU (much faster, mexGPUall first)
ops.parfor              = 1; % whether to use parfor to accelerate some parts of the algorithm
ops.verbose             = 1; % whether to print command line progress
ops.showfigures         = 0; % whether to plot figures during optimization
% options for reading/saving files
ops.root        = metadata.root;
ops.fbinary     = metadata.binpath;
ops.fproc       = metadata.whpath;
% maximum RAM the algorithm will try to use for storing whitened data; on Windows it will autodetect.
ops.ForceMaxRAMforDat   = 0e9;
ops.lowmem = 1; % use low memory
ops.epu = Inf;
ops.fracse = 0.1;
%=========================================================================
% options for channel whitening
ops.whitening           = 'full'; % type of whitening (default 'full', for 'noSpikes' set options for spike detection below)
ops.nSkipCov            = 10; % compute whitening matrix from every N-th batch (1)
ops.whiteningRange      = 32; % how many channels to whiten together (Inf for whole probe whitening, should be fine if Nchan<=32)
%=========================================================================
% channel-specific options
ops.meatype     = metadata.meatype;
updateops = false;
switch metadata.meatype
    case '252MEA10030'
        meaChannelMap([16 16], 100,  fullfile(ops.root, 'ks_sorted'), 1);
        ops.nfilt_factor        = 8;
        ops.NchanTOT            = 252;
    case '252MEA6010'
        meaChannelMap([16 16], 60,  fullfile(ops.root, 'ks_sorted'), 1);
        ops.nfilt_factor        = 8;
        ops.NchanTOT            = 252;
     case '252MEA3008'
        meaChannelMap([16 16], 30,  fullfile(ops.root, 'ks_sorted'), 1);
        ops.nfilt_factor        = 8;
        ops.NchanTOT            = 252;
    case '252MEA20030'
        meaChannelMap([16 16], 200,  fullfile(ops.root, 'ks_sorted'), 1);
        ops.nfilt_factor        = 8;
        ops.NchanTOT            = 252;
    case '60MEA10030'
        meaChannelMap([8 8], 100,  fullfile(ops.root, 'ks_sorted'), 1);
        ops.nfilt_factor        = 8;
        ops.NchanTOT            = 60;
    case '60pMEA10030'
        meaChannelMap([10 6], 100,  fullfile(ops.root, 'ks_sorted'), 0);
        ops.nfilt_factor        = 9;
        ops.NchanTOT            = 60;
    case '60MEA20030'
        meaChannelMap([8 8], 200,  fullfile(ops.root, 'ks_sorted'), 1);
        ops.nfilt_factor        = 8;
        ops.NchanTOT            = 60;
    case '60mea20030cellculture'
        meaChannelMap([8 8], 200,  fullfile(ops.root, 'ks_sorted'), 1);
        ops.nfilt_factor        = 5;
        ops.NchanTOT            = 60;
        updateops = true;
    case '60mea20030hippocampus'
        meaChannelMap([8 8], 200,  fullfile(ops.root, 'ks_sorted'), 1);
        ops.nfilt_factor        = 4;
        ops.NchanTOT            = 60;
        updateops = true;
    case '60MEA10010'
        meaChannelMap([8 8], 100,  fullfile(ops.root, 'ks_sorted'), 1);
        ops.nfilt_factor        = 8;
        ops.NchanTOT            = 60;
    case {'60Hexa', '60hexa'}
        hexaChannelMap(fullfile(ops.root, 'ks_sorted'));
        ops.nfilt_factor        = 7;
        ops.NchanTOT            = 60;
end
%==========================================================================
% Options for excluding channels
ops.minfr_goodchannels  = 0.1; %to exclude empty channels
ops.madTh               = -6*1.4826; %to exclude empty channels
%==========================================================================
% other options
ops.chanMap             = fullfile(ops.root, 'ks_sorted','chanMap.mat'); % make this file using createChannelMapFile.m
ops.nNeighPC            = 16; % visualization only (Phy): number of channnels to mask the PCs, leave empty to skip (12)
ops.nNeigh              = 16; % visualization only (Phy): number of neighboring templates to retain projections of (16)
ops.fs                  = metadata.bininfo.fs; %sampling frequency
%==========================================================================
ops.nt0                 = floor(round(24*ops.fs/1e4)/2)*2+1; %spike template time bins
ops.nt0min              = floor(round(8*ops.fs/1e4)/2)*2; %spike template time bins
% other options for controlling the model and optimization
ops.Nrank               = 3;    % matrix rank of spike template model (3)
ops.nfullpasses         = 6;    % number of complete passes through data during optimization (6)
ops.maxFR               = 400000;  % maximum number of spikes to extract per batch (20000)
ops.fshigh              = 300;   % frequency for high pass filtering
ops.CAR                 = 1;    % option for doing common average referencing
% ops.fslow             = 2000;   % frequency for low pass filtering (optional)
ops.filter              = false; % don't filter data if already filtered
ops.ntbuff              = 64; % samples of symmetrical buffer for whitening and spike detection
ops.scaleproc           = 200;   % int16 scaling of whitened data
ops.NT                  = 64*round(800*ops.fs/1e4) + ops.ntbuff;% this is the batch size (try decreasing if out of memory)
% for GPU should be multiple of 32 + ntbuff
%==========================================================================
% the following options can improve/deteriorate results.
% when multiple values are provided for an option, the first two are beginning and ending anneal values,
% the third is the value used in the final pass.
ops.Th               = [3   6  4];  % threshold for detecting spikes on template-filtered data, (suggested values were [4 10 10], )
if ops.fs > 1.5e4; ops.Th = [4 8 4]; end
ops.lam              = [15 70 70];   % large means amplitudes are forced around the mean, (suggested values were [5 20 20], [10 30 30])	, ours was [15 50 50]
ops.nannealpasses    = 4;            % should be less than nfullpasses (4)
ops.momentum         = 1./[20 400];  % start with high momentum and anneal (1./[20 1000])
ops.shuffle_clusters = 1;            % allow merges and splits during optimization (1)
ops.mergeT           = .1;           % upper threshold for merging (.1)
ops.splitT           = .1;           % lower threshold for splitting (.1)
ops.freqUpdate       = 100;          %ceil(1600 * ops.fs/25e3)      % original was 1600
ops.minSpks          = 800;          % minimum number of spikes allowed per cluster (200)
%==========================================================================
% options for initializing spikes from data
ops.initialize      = 'fromData';    %'fromData' or 'no'
ops.spkTh           = -4;      % spike threshold in standard deviations (4)
ops.loc_range       = [round(1.5*ops.fs/1e4) 0];  % ranges to detect peaks; plus/minus in time and channel ([3 1])
ops.long_range      = [round(10*ops.fs/1e4)  1]; % ranges to detect isolated peaks ([30 6])
ops.maskMaxChannels = 5;       % how many channels to mask up/down ([5])
ops.crit            = .65;     % upper criterion for discarding spike repeates (0.65)
ops.nFiltMax        = 100000;   % maximum "unique" spikes to consider (10000)
ops.nskip           = 20;
%==========================================================================
if updateops
    ops = updateOpsMEA(metadata, ops);
end
end

