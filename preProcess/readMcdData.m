function [vall] = getMCDdata(mcdpath, stimsamples, chIds, startsample,nsamples)
%GETMCDDATA
%==========================================================================
[dllpath,libtoload] = getMCSdllPath();
mcdfilenames = dir([mcdpath,filesep,'*.mcd']);
%sort to get correct order
[~, reindex]=sort(str2double(regexp(({mcdfilenames(:).name}),'\d+','match','once')));
mcdfilenames={mcdfilenames(reindex).name};
%==========================================================================
cumsamples=cumsum(stimsamples(:));

nall=histc(startsample:startsample+nsamples-1,[1 cumsamples(1:end)'+1]);
nall=nall(1:end-1);
stimIds=find(nall);
startpoints=ones(size(nall));
startpoints(stimIds(1))=stimsamples(stimIds(1))-nall(stimIds(1))+1;
startpoints=startpoints(stimIds); nall=nall(stimIds);

gainAmp=1100; newRange=2^15*[-1 1]; rangeAmp=2^12*[-1 1]; %in mV
multFact=(gainAmp*1e3)*range(newRange)/range(rangeAmp);
%==========================================================================
%initialize values empty
vall=zeros(numel(chIds),sum(nall),'int16');
startidx=1;
for ii=1:numel(stimIds)    
    mcdpathname = [mcdpath,filesep,mcdfilenames{stimIds(ii)}];
    % first open the dll file
    nsresult = mexprog(18, [dllpath, filesep, libtoload]);  %#ok   % ns_SetLibrary
    % opening file
    [nsresult, hfile] = mexprog(1, mcdpathname);  %ns_OpenFile
    [~,~,vchannels]=mexprog(8,hfile, chIds-1, startpoints(ii)-1, nall(ii));%GetAnalogData

    endidx=startidx+nall(ii)-1;
    vall(:,startidx:endidx) = int16(vchannels*multFact)';
    startidx=endidx+1;
    % Close data file. Should be done by the library but just in case.
    nsresult = mexprog(14, hfile);  clear mexprog; %#ok    % ns_CloseFile % Unload DLL
    clear vchannels; clear hfile;
end
%==========================================================================
end
