function batch_run_ks(varargin)

%==========================================================================
p = inputParser();
p.addParameter('mcdatapath', [], @(x) ischar(x));
p.addParameter('MEAtype', [], @(x) ischar(x));
p.addParameter('Experimenttype', [], @(x) ischar(x));
p.addParameter('ChannelstoDelete', [], @(x) ischar(x));
p.addParameter('AnalyzeMultipleExp', true, @(x) islogical(x));
p.addParameter('verbose', true, @(x) islogical(x));
p.parse(varargin{:});

verbose = p.Results.verbose;
multiexpflag = p.Results.AnalyzeMultipleExp;

rootpaths = p.Results.mcdatapath;
meatypes = p.Results.MEAtype;
exptypes = p.Results.Experimenttype; % option to change initial ops for cell culture, MHK Nov 2019
chans2del = p.Results.ChannelstoDelete; % option to change initial ops for deleting channels, MHK Dec 2019

if isempty(rootpaths) || ~exist(rootpaths,'dir')
    if multiexpflag
        [rootpaths, meatypes, exptypes] = getmultiplepaths(rootpaths);
    else
        rootpaths = uigetdir([],'Select mcd data folder');
        rootpaths = {rootpaths}; % convert to cell to run it seemlessly with batch files
    end 
end
%==========================================================================
up = userpath; [pp, ~] = fileparts(up);
KilosortPath  = fullfile(pp, 'GitHub\KiloSortMEA');
NpyMatlabPath = fullfile(pp, 'GitHub\npy-matlab');
addpath(genpath(KilosortPath)); addpath(genpath(NpyMatlabPath));
%================================================================
for iexp = 1:numel(rootpaths)
    %----------------------------------------------------------------------
    kssortedpath = fullfile(rootpaths{iexp},'ks_sorted');
    % make ks sorted folder
    if ~exist(kssortedpath,'dir'), mkdir(kssortedpath); end
    %----------------------------------------------------------------------
    % make diary
    diarypath = fullfile(kssortedpath, 'ks_output_logger.txt');
    if exist(diarypath, 'file'); delete(diarypath); end
    diary(diarypath); diary on;
    %----------------------------------------------------------------------
    binname = 'alldata.dat';
    binpath = fullfile(kssortedpath, binname);
    %----------------------------------------------------------------------
    metadata = [];
    metadata.root = rootpaths{iexp}; 
    metadata.meatype = meatypes{iexp};
    metadata.exptypes = exptypes{iexp};
    %metadata.chans2del = chans2del{iexp};
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
        %----------------------------------------------------------------------
        %read frametimes
        if ~exist(fullfile(rootpaths{iexp}, 'frametimes'),'dir')
            fprintf('Extracting frametimings...\n');
            readFrametimes('mcdatapath', rootpaths{iexp});
        end
        %----------------------------------------------------------------------
        disp('Kilosort binary missing, starting conversion...')
        metadata = getmcdmetadata(metadata,verbose);

        % do conversion
        convpath = fullfile('F:\DATA_sorted', binname);
        bininfo = convertToKsRawBinary(metadata, convpath);
        disp('Conversion completed!')
        
        %move file to the root
        disp('Moving the file back to root...'); tic;
        save(fullfile(kssortedpath, 'bininfo.mat'),'bininfo', '-v7.3');
        movefile(convpath, fullfile(metadata.root,'ks_sorted'));
        % write text file for eventmarkers used in Phy amplitude view
        ksEventMarkers(kssortedpath, metadata.root);
        fprintf('Done! Took %.2f min\n', toc/60);
        
    end
    %----------------------------------------------------------------------
    metadata.bininfo = bininfo;
    metadata.binpath = binpath;
    metadata.whpath = fullfile('F:\DATA_sorted', 'temp_wh.dat');
    %----------------------------------------------------------------------
    % get options and make channel map
    ops = getKsOptionsMEA(metadata);
    %----------------------------------------------------------------------
    % sort data
    gpuDevice(1); %initialize GPU (erases any existing GPU arrays)
    rez        = preprocessData(ops); % preprocess data and extract spikes for initialization
    rez        = fitTemplates(rez); % fit templates iteratively
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
    diary off;
    %----------------------------------------------------------------------
end
%==========================================================================
end

function mtdat = getmcdmetadata(mtdat, verbose)

stimfiles = dir([mtdat.root,filesep,'*.mcd']);
mtdat.recording_type = 'mcd';
if numel(stimfiles) == 0
    stimfiles = dir([mtdat.root,filesep,'*.h5']);
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

function [pathlist, meatypelist, exptypelist] = getmultiplepaths(batchtxtpath)

if isempty(batchtxtpath) || ~exist(batchtxtpath,'file')
    [batchpathfile,batchfilepath] = uigetfile('*.txt','Select the text file for all the data folders');
else
    [batchfilepath,batchpathfile,batchfileformat] = fileparts(batchtxtpath);
    batchpathfile = [batchpathfile,batchfileformat];
end

fid = fopen(fullfile(batchfilepath,batchpathfile),'r');
C = textscan(fid,'%s %s %s','whitespace','','Delimiter',',');
fclose(fid);

pathlist = C{1};
meatypelist = strrep(C{2},' ','');
if size(C{1},1) > 1 && size(C{1},1) > size(C{3},1) % this to fill up last empty text
    C{3}{size(C{1},1)} = ''; 
end
if isempty(C{3})
    exptypelist = {''};
else
    exptypelist = C{3};
end

end