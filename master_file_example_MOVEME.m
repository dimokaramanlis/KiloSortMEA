%==========================================================================
%Setup paths to to kilosort and npy-matlab folders
KilosortPath='C:\Users\Karamanlis_Dimokrati\Documents\Repositories\KiloSort';
NpyMatlabPath='C:\Users\Karamanlis_Dimokrati\Documents\Repositories\npy-matlab';
addpath(genpath(KilosortPath)); addpath(genpath(NpyMatlabPath));
%==========================================================================
%Run configuration file, take from Github folder and put it somewhere else (together with the master_file)
run(fullfile(KilosortPath, 'configFiles','TestConfig252MEA.m'));
create252ChannelMapFile(ops.root); 
if exist((ops.fproc),'file'); delete(ops.fproc); end
%==========================================================================
%Do sorting
if ops.GPU; gpuDevice(1); end %initialize GPU (erases any existing GPU arrays)
[rez, DATA, uproj] = preprocessData(ops); % preprocess data and extract spikes for initialization
rez                = fitTemplates(rez, DATA, uproj); clear uproj; % fit templates iteratively
if ops.GPU; gpuDevice(1); end %initialize GPU (erases any existing GPU arrays)
rez                = fullMPMU(rez, DATA);% extract final spike times (overlapping extraction)
delete(ops.fproc); % remove temporary file
%==========================================================================
% AutoMerge. rez2Phy will use for clusters the new 5th column of st3 if you run this)
%rez2 = merge_posthoc2(rez);
%==========================================================================
% save matlab results file % save python results file for Phy
save(fullfile(ops.root,  'rez.mat'), '-struct','rez', '-v7.3');
rezToPhy(rez, ops.root);
%==========================================================================