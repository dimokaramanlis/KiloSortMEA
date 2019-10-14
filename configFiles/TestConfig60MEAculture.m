clear ops;
%==========================================================================
ops.GPU                 = 1; % whether to run this code on an Nvidia GPU (much faster, mexGPUall first)		
ops.parfor              = 1; % whether to use parfor to accelerate some parts of the algorithm		
ops.verbose             = 1; % whether to print command line progress		
ops.showfigures         = 1; % whether to plot figures during optimization		
%==========================================================================		
ops.root = uigetdir('D:/','Give me the directory of the experiment');
%[~, dirname] = fileparts(ops.root);
ops.datatype            = 'mcd';  % binary ('dat', 'bin'), 'openEphys' or 'mcd'
%binpathD = fullfile('D:/TestData/', dirname);
ops.binpathD = ops.root ;   % added by MHK
if ~exist(ops.binpathD,'dir'); mkdir(ops.binpathD); end
ops.fbinary             = fullfile(ops.binpathD, '/alldata.dat'); % will be created for 'openEphys' and 'mcd'	
ops.fproc               = fullfile(ops.binpathD, '/whitenedtemplates/temp_wh.dat');%'F:/Kilosort/DATA/temp_wh.dat'; % residual from RAM of preprocessed data	
if ~(exist(fileparts(ops.fproc),'dir')), mkdir(fileparts(ops.fproc)); end
%==========================================================================
% define the channel map as a filename (string) or simply an array		
ops.chanMap             = fullfile(ops.root, 'chanMap.mat'); % make this file using createChannelMapFile.m		
ops.Nfilt               = 32*4;  % number of clusters to use (2-4 times more than Nchan, should be a multiple of 32)     		
ops.nNeighPC            = 12; % visualization only (Phy): number of channnels to mask the PCs, leave empty to skip (12)		
ops.nNeigh              = 16; % visualization only (Phy): number of neighboring templates to retain projections of (16)		
ops.fs                  = 2e4; %sampling frequency		
%==========================================================================		
% options for channel whitening		
ops.whitening           = 'full'; % type of whitening (default 'full', for 'noSpikes' set options for spike detection below)		
ops.nSkipCov            = 5; % compute whitening matrix from every N-th batch (1)		
ops.whiteningRange      = 32; % how many channels to whiten together (Inf for whole probe whitening, should be fine if Nchan<=32)		
%==========================================================================		
ops.criterionNoiseChannels = 0.2; % fraction of "noise" templates allowed to span all channel groups (see createChannelMapFile for more info). 		
% ops.nt0                 = floor(18e-4*ops.fs/2)*2+1; %spike template time bins, it has to be an odd number!
% ops.nt0min              = ceil(6e-4*2.5e4/2)*2;
ops.nt0                 = 51; %spike template time bins, it has to be an odd number!
ops.nt0min              = 18;
% other options for controlling the model and optimization		
ops.Nrank               = 3;    % matrix rank of spike template model (3)		
ops.nfullpasses         = 6;    % number of complete passes through data during optimization (6)		
ops.maxFR               = 20000;  % maximum number of spikes to extract per batch (20000)		
ops.fshigh              = 300;   % frequency for high pass filtering	
ops.CAR                 = 1;    % option for doing common average referencing
% ops.fslow             = 2000;   % frequency for low pass filtering (optional)
ops.filter              = true; % don't filter data if already filtered
ops.ntbuff              = 64; % samples of symmetrical buffer for whitening and spike detection		
ops.scaleproc           = 200;   % int16 scaling of whitened data		
ops.NT                  = 32*1024+ops.ntbuff;% this is the batch size (try decreasing if out of memory) 		
% for GPU should be multiple of 32 + ntbuff
%==========================================================================		
% the following options can improve/deteriorate results. 		
% when multiple values are provided for an option, the first two are beginning and ending anneal values, 		
% the third is the value used in the final pass. 		
ops.Th               = [4 10 10];  % threshold for detecting spikes on template-filtered data, (suggested values were [4 10 10], )
ops.lam              = [15 50 50];   % large means amplitudes are forced around the mean, (suggested values were [5 20 20], [10 30 30])		
ops.nannealpasses    = 4;            % should be less than nfullpasses (4)		
ops.momentum         = 1./[20 200];  % start with high momentum and anneal (1./[20 1000])		
ops.shuffle_clusters = 1;            % allow merges and splits during optimization (1)		
ops.mergeT           = .1;           % upper threshold for merging (.1)		
ops.splitT           = .1;           % lower threshold for splitting (.1)
ops.freqUpdate       = 40;
ops.muTh             = 10;          % minimum mu ("variance") required per cluster (10)
ops.minSpks          = 50;         % minimum number of spikes allowed per cluster (200)
%==========================================================================		
% options for initializing spikes from data		
ops.initialize      = 'no';    %'fromData' or 'no'		
ops.spkTh           = -4;      % spike threshold in standard deviations (4)		
ops.loc_range       = [5 4];  % ranges to detect peaks; plus/minus in time and channel ([3 1])		
ops.long_range      = [30 6]; % ranges to detect isolated peaks ([30 6])		
ops.maskMaxChannels = 5;       % how many channels to mask up/down ([5])		
ops.crit            = .65;     % upper criterion for discarding spike repeates (0.65)		
ops.nFiltMax        = 20000;   % maximum "unique" spikes to consider (10000)		
ops.nskip           = 1;
%==========================================================================		
% options for posthoc merges (under construction)		
ops.fracse  = 0.1; % binning step along discriminant axis for posthoc merges (in units of sd)		
ops.epu     = Inf;
%==========================================================================
% maximum RAM the algorithm will try to use for storing whitened data; on Windows it will autodetect.
ops.ForceMaxRAMforDat   = 0e9; 
%==========================================================================