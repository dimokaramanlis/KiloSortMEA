function batch_run_ks(varargin)

%==========================================================================
p = inputParser();
p.addParameter('mcdatapath', [], @(x) ischar(x));
p.addParameter('MEAtype', [], @(x) ischar(x));
p.addParameter('AnalyzeMultipleExp', true, @(x) islogical(x));
p.addParameter('verbose', true, @(x) islogical(x));
p.parse(varargin{:});

verbose = p.Results.verbose;
multiexpflag = p.Results.AnalyzeMultipleExp;

rootpaths = p.Results.mcdatapath;
meatypes = p.Results.MEAtype;
if isempty(rootpaths) || ~exist(rootpaths,'dir')
    if multiexpflag
        [rootpaths, meatypes] = getmultiplepaths(rootpaths);
    else
        rootpaths = uigetdir([],'Select mcd data folder');
        rootpaths = {rootpaths}; % convert to cell to run it seemlessly with batch files
    end 
end
%==========================================================================
KilosortPath ='C:\Users\admin_lokal\Documents\GitHub\KiloSortMEA';
NpyMatlabPath ='C:\Users\admin_lokal\Documents\GitHub\npy-matlab';
addpath(genpath(KilosortPath)); addpath(genpath(NpyMatlabPath));
%==========================================================================
for iexp = 1:numel(rootpaths)
    
    %----------------------------------------------------------------------
    if ~exist(fullfile(rootpaths{iexp},'ks_sorted'),'dir')
        mkdir(fullfile(rootpaths{iexp},'ks_sorted'));
    end
    binname = 'alldata.dat'; 
    binpath = fullfile(rootpaths{iexp},'ks_sorted', binname);
    %----------------------------------------------------------------------
    metadata = [];
    metadata.root = rootpaths{iexp}; 
    metadata.meatype = meatypes{iexp};
    %----------------------------------------------------------------------
    % search for ks binary in the root folder or do conversion
    if exist(binpath,'file')
        
        disp('Kilosort binary found!')
        % load bininfo
        bininfopath = fullfile(metadata.root,'ks_sorted','bininfo.mat');
        if ~exist(bininfopath,'file')
            error("Can't find bininfo.mat, exiting"); 
        end
        ifile = load(bininfopath); bininfo = ifile.bininfo;
        
    else
        
        disp('Kilosort binary missing, starting conversion...')
        metadata = getmcdmetadata(metadata,verbose);

        % do conversion
        convpath = fullfile('F:\DATA_sorted', binname);
        bininfo = convertToKsRawBinary(metadata, convpath);
        disp('Conversion completed!')
        
        %move file to the root
        disp('Moving the file back to root...'); tic;
        movefile(convpath, fullfile(metadata.root,'ks_sorted'));
        save(fullfile(metadata.root,'ks_sorted','bininfo.mat'),'bininfo', '-v7.3');
        fprintf('Done! Took %.2f min\n', toc/60);
        
    end
    metadata.bininfo = bininfo;
    metadata.binpath = binpath;
    metadata.whpath = fullfile('F:\DATA_sorted', 'temp_wh.dat');
    %----------------------------------------------------------------------
    % get options and make channel map
    ops = getKsOptionsMEA(metadata);
    %----------------------------------------------------------------------
    % sort data
    if ops.GPU; gpuDevice(1); end %initialize GPU (erases any existing GPU arrays)
    rez        = preprocessDataNew(ops); % preprocess data and extract spikes for initialization
    rez        = fitTemplatesNew(rez); % fit templates iteratively
    if ops.GPU; gpuDevice(1); end %initialize GPU (erases any existing GPU arrays)
    rez                = fullMPMUNew(rez);% extract final spike times (overlapping extraction)
    delete(ops.fproc); % remove temporary file
    %----------------------------------------------------------------------
    % save sorted data to the original folder
    rezToPhyNew(rez, fullfile(ops.root, 'ks_sorted'));     %rezToPhy
    rez.cProj = []; rez.cProjPC = [];
    % save matlab results file 
    save(fullfile(ops.root, 'ks_sorted','rez.mat'),'rez', '-v7.3');
    clear ops rez metadata;
end
%==========================================================================
end

function mtdat = getmcdmetadata(mtdat, verbose)

stimfiles = dir([mtdat.root,filesep,'*.mcd']);
mtdat.recording_type = 'mcd';
if numel(stimfiles) == 0
    stimfiles = dir([rootpath,filesep,'*.h5']);
    mtdat.recording_type = 'h5';
end

[~, expname]= fileparts(mtdat.root);

if isempty(stimfiles)
    error('Hey yo!, there aint no recoreded MCD/H5 data in this folder! good luck with analysis');
end
if verbose
    disp([repmat('-',1,20),' Experiment : ',expname,' ', repmat('-',1,20)]);        
end

%sort filenames
namelist = {stimfiles.name}';
filenum = cellfun(@(x)sscanf(x,'%d_yy.txt'),namelist);
[~,Sidx] = sort(filenum);

stimfiles = stimfiles(Sidx);

mtdat.mcdfilenames = {stimfiles.name}';
mtdat.mcdfilesize = [stimfiles.bytes]'/(2^10^3);
mtdat.totalexpsize = sum(mtdat.mcdfilesize);
mtdat.exptime = {stimfiles.date}';
[str,dt] = deal(cell(size(stimfiles,1),1));
for jj = 1:size(stimfiles,1)
    str{jj} = [num2str(jj,'%02d'),':',repmat(' ',1,5),mtdat.mcdfilenames{jj}(1:15),' ... ',...
        mtdat.mcdfilenames{jj}(end-3:end), repmat(' ',1,5),'size: ',num2str(mtdat.mcdfilesize(jj),'%.3g'),...
        ' GB', repmat(' ',1,5),'recorded at: ', mtdat.exptime{jj}];
        gp = strfind(mtdat.exptime{jj},':');
    dt{jj} = mtdat.exptime{jj}(1:gp(1)-4);
end
mtdat.expdate = cell2mat(unique(dt));
mtdat.label = str;
if verbose
    disp(str);
    disp([repmat('-',1,40),'> Total size: ', num2str(mtdat.totalexpsize,'%.3g')]);
    disp([repmat('-',1,40),'> Experiment date: ', mtdat.expdate(1,:)]);
    disp(repmat(' ',2,1))
end


end


function [pathlist, meatypelist] = getmultiplepaths(batchtxtpath)

if isempty(batchtxtpath) || ~exist(batchtxtpath,'file')
    [batchpathfile,batchfilepath] = uigetfile('*.txt','Select the text file for all the data folders');
else
    [batchfilepath,batchpathfile,batchfileformat] = fileparts(batchtxtpath);
    batchpathfile = [batchpathfile,batchfileformat];
end

fid = fopen(fullfile(batchfilepath,batchpathfile),'r');
C = textscan(fid,'%s %s','whitespace','','Delimiter',',');
fclose(fid);

pathlist = C{1};
meatypelist = strrep(C{2},' ','');

end
