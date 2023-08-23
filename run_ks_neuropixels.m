
%==========================================================================
up = userpath; [pp, ~] = fileparts(up);
KilosortPath  = fullfile(pp, 'GitHub', 'KiloSortMEA');
NpyMatlabPath = fullfile(pp, 'GitHub', 'npy-matlab');
addpath(genpath(KilosortPath)); addpath(genpath(NpyMatlabPath));
temppath = 'C:\';
%================================================================
[targetfolders, namestoread] = recordingPaths('AM090_AM097');
for itargetfile = 1:numel(targetfolders)

    
    %----------------------------------------------------------------------
    %metadata.root = 'E:\97_FullSession_20230816';
    metadata.root = targetfolders{itargetfile};
    kssortedpath = fullfile(metadata.root, 'ks_sorted');
    if ~exist(kssortedpath, 'dir')
        mkdir(kssortedpath);
    end

    dpall = namestoread{itargetfile};
%     dpall = {'Session1_g0_t0.imec1.ap.bin', 'Session2_g0_t0.imec1.ap.bin','Session1_g0_t0.imec1.apv.bin'};
%     for ii = 1:numel(dpall)
%         dpall{ii} = fullfile(metadata.root, dpall{ii});
%     end 
    %----------------------------------------------------------------------
    binname = 'alldata.dat';
    binpath = fullfile(kssortedpath, binname);
    
    samplelist = concatenateAndCleanBinaries(dpall, binpath);
    %%
    %----------------------------------------------------------------------
    bininfopath = fullfile(kssortedpath,'samplelist.mat');
    ifile = load(bininfopath); 
    bininfo.stimsamples = ifile.samplelist;
    bininfo.fs       = 30000;
    bininfo.NchanTOT = 384;
    %----------------------------------------------------------------------
    metadata.bininfo = bininfo;
    metadata.binpath = binpath;
    metadata.whpath = fullfile(temppath, 'DATA_sorted', 'temp_wh.dat');
    %----------------------------------------------------------------------
    % get options and make channel map
    ops = getKsOptionsNP(metadata);
    %----------------------------------------------------------------------
    % sort dataww
    gpuDevice(1); %initialize GPU (erases any existing GPU arrays)
    rez        = preprocessData(ops); % preprocess data and extract spikes for initialization
    rez        = fitTemplates(rez); % fit templates iteratively
    disp(rez.ops.NchanTOT)
    gpuDevice(1);  %initialize GPU (erases any existing GPU arrays)
    rez                = fullMPMUNew2(rez);% extract final spike times (overlapping extraction)
    delete(ops.fproc); % remove temporary file
    %----------------------------------------------------------------------
    % save sorted data to the original folder
    fprintf('Saving results to Phy  \n')
    rezToPhy(rez, kssortedpath);     %rezToPhy
    rez.cProj = []; rez.cProjPC = [];
    % save matlab results file 
    fprintf('Saving final results in rez  \n')
    save(fullfile(ops.root, 'ks_sorted','rez.mat'),'rez', '-v7.3');
    clear ops metadata;
    %----------------------------------------------------------------------
end
%==========================================================================
