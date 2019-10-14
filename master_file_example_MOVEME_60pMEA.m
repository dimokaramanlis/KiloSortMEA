%==========================================================================
%Setup paths to to kilosort and npy-matlab folders
KilosortPath='C:\Users\admin_lokal\Documents\GitHub\KiloSortMEA';
NpyMatlabPath='C:\Users\admin_lokal\Documents\GitHub\npy-matlab';
addpath(genpath(KilosortPath)); addpath(genpath(NpyMatlabPath));
%==========================================================================
%Run configuration file, take from Github folder and put it somewhere else (together with the master_file)
run(fullfile(KilosortPath, 'configFiles','TestConfig60pMEA.m'));
%create252ChannelMapFile(ops.root); 
meaChannelMap([10 6], 100, ops.root, 0);

if exist((ops.fproc),'file'); delete(ops.fproc); end
%==========================================================================
%Do sorting
if ops.GPU; gpuDevice(1); end %initialize GPU (erases any existing GPU arrays)
[rez, DATA]        = preprocessData(ops); % preprocess data and extract spikes for initialization
rez                = fitTemplates(rez, DATA); % fit templates iteratively
if ops.GPU; gpuDevice(1); end %initialize GPU (erases any existing GPU arrays)
rez                = fullMPMU(rez, DATA);% extract final spike times (overlapping extraction)
delete(ops.fproc); % remove temporary file
%if (exist(fileparts(ops.fproc),'dir')), rmdir(fileparts(ops.fproc)); end % delete temp folder
%==========================================================================
% AutoMerge. rez2Phy will use for clusters the new 5th column of st3 if you run this)
%rez2 = merge_posthoc2(rez);
%==========================================================================
% save python results file for Phy
%rezToPhy(rez, rez.ops.root);
rezToPhy(rez, ops.binpathD);
%save(fullfile(ops.root,  'rezfull.mat'),'rez', '-v7.3');
% discard features in final rez file (too slow to save)
rez.cProj = []; rez.cProjPC = [];
% save matlab results file 
%save(fullfile(ops.root,  'rez.mat'),'rez', '-v7.3');
save(fullfile(ops.binpathD,  'rez.mat'),'rez', '-v7.3');
%==========================================================================