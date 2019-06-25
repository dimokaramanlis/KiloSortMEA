function [ops] = convertMcdToRawBinary(ops)
%CONVERTMCDTORAWBINARY Save mcd files as binary without analog channels
%Neuroshare functions and dlls have to be in MATLAB path
%We can potentially add what's needed in Kilosort's folder
%Also saves the time samples correponding to the beginning of each stimulus
%--------------------------------------------------------------------------
tic;
%get mcd filenames
mcdfilenames = dir([ops.root,filesep,'*.mcd']);
[~, reindex]=sort(str2double(regexp(({mcdfilenames(:).name}),'\d+','match','once')));
mcdfilenames={mcdfilenames(reindex).name}'; Nfiles=numel(mcdfilenames);
%--------------------------------------------------------------------------
%load the dll file
[dllpath,libtoload] = getMCSdllPath();
nsresult=mexprog(18, [dllpath, filesep, libtoload]);  %set dll library
%--------------------------------------------------------------------------
%get information about the recording time
stimsamples=zeros(numel(mcdfilenames),1);
for imcd=1:numel(mcdfilenames)
    mcdpathname = [ops.root,filesep,mcdfilenames{imcd}]; %get mcd path
    [nsresult, hfile] = mexprog(1, mcdpathname); %open file
    [nsresult, mcdfileInfo] = mexprog(3, hfile); %get file info
    stimsamples(imcd)=mcdfileInfo.TimeSpan/mcdfileInfo.TimeStampResolution;
    nsresult = mexprog(14, hfile);%close file
end
NchanTOT=mcdfileInfo.EntityCount;
stimsamples=floor(stimsamples);
ops.stimsamples=stimsamples;
fs = 1/mcdfileInfo.TimeStampResolution; % sampling frequency
if fs~=ops.fs
    warning('Sampling frequency set is different from MCD files! Fixing...');
    ops.fs=fs;
end
fprintf('Total length of recording is %2.2f min...\n',sum(stimsamples)/fs/60);
%--------------------------------------------------------------------------
%get information about the array arrangement and the signal
[nsresult, hfile] = mexprog(1, [ops.root,filesep,mcdfilenames{1}]); %open file
[nsresult, chinfos] = mexprog(4, hfile,0:(NchanTOT-1)); %get channel info
[nsresult, volinfos] = mexprog(7, hfile,0:(NchanTOT-1)); % get general info
nsresult=mexprog(14, hfile);%close data file. 
labellist = {chinfos.EntityLabel}; clear chinfos; %extract labels of the entities
maxVoltage=volinfos(1).MaxVal; minVoltage=volinfos(1).MinVal;
resVoltage=volinfos(1).Resolution; clear volinfos;
newRange=2^15*[-1 1]; multFact=range(newRange)/(maxVoltage-minVoltage);
%--------------------------------------------------------------------------
% get the channel names based on the map of the array
chanMap=getChannelMapMEA(labellist);
%--------------------------------------------------------------------------
fprintf('Saving .mcd data as .dat...\n');

maxSamples=64e5;

fidOut= fopen(ops.fbinary, 'W'); %using W (capital), makes writing ~4x faster
msg=[]; 
for iFile=1:Nfiles
    mcdpathname = [ops.root,filesep,mcdfilenames{iFile}];
    nsamples=stimsamples(iFile);
    Nchunk=ceil(nsamples/maxSamples);
    
    [nsresult, hfile] = mexprog(1, mcdpathname);  %open file
    for iChunk=1:Nchunk
        offset = max(0, (maxSamples * (iChunk-1)));
        sampstoload=min(nsamples-offset,maxSamples);
        [~,~,dat]=mexprog(8,hfile, chanMap, offset, sampstoload);%read data
        dat=int16(dat*multFact)';
%         nsampcurr=size(dat,2);
%         if nsampcurr<sampstoload
%             dat(:,nsampcurr+1:int64(sampstoload))=repmat(dat(:,nsampcurr),...
%                 1,int64(sampstoload)-nsampcurr);
%         end
        fwrite(fidOut, dat, 'int16');
    end
    nsresult = mexprog(14, hfile); %close file

    %report status
    fprintf(repmat('\b', 1, numel(msg)));
    msg=sprintf('Time %3.0f min. Mcd files processed %d/%d \n',...
        toc/60, iFile,Nfiles); 
    fprintf(msg);
    
end
fclose(fidOut); clear mexprog; %unload DLL
%--------------------------------------------------------------------------
end

function chanMap = getChannelMapMEA(labellist)
    anlg=contains(labellist,'anlg0001');
    chnames = regexprep(extractAfter(labellist,'      '), '\s+', '')';
    R = cell2mat(regexp(chnames,'(?<Name>\D+)(?<Nums>\d+)','names'));
    namesCell=[{R.Name}' {R.Nums}'];
    %remove analog channels already before sorting (don't have to be sorted)
    namesCell(anlg,:)=[{'A'} {'1'}; {'A'} {'16'};{'R'} {'1'};{'R'} {'16'}];
    [~,chmeaidx] = sortrows([namesCell(:,1) num2cell(cellfun(@(x)str2double(x),namesCell(:,2)))]);
    chanMap=chmeaidx(~anlg(chmeaidx))-1;
end

function [dllpath,libtoload] = getMCSdllPath()
%GETMCSDLLPATH Summary of this function goes here

dlllocation = which('load_multichannel_systems_mcd');
dllpath = fileparts(dlllocation);

switch computer()
    case 'PCWIN'; libtoload = 'nsMCDLibraryWin32.dll';
    case 'GLNX86'; libtoload = 'nsMCDLibraryLinux32.so';
    case 'PCWIN64'; libtoload = 'nsMCDLibraryWin64.dll';
    case 'GLNXA64'; libtoload = 'nsMCDLibraryLinux64.so';
    case 'MACI64'; libtoload = 'nsMCDLibraryMacIntel.dylib';
    otherwise
        disp('Your architecture is not supported'); return;
end
end