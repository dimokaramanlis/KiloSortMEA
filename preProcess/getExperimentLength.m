function [totalsamples] = getExperimentLength(mcdpath)
%GETEXPERIMENTLENGTH Summary of this function goes here
%   Detailed explanation goes here
%--------------------------------------------------------------------------
[dllpath,libtoload] = getMCSdllPath();
mcdfilenames = dir([mcdpath,filesep,'*.mcd']);
%sort to get correct order
[~, reindex]=sort(str2double(regexp(({mcdfilenames(:).name}),'\d+','match','once')));
mcdfilenames={mcdfilenames(reindex).name};

nsresult = mexprog(18, [dllpath, filesep, libtoload]);  %ns_SetLibrary
totalsamples=zeros(numel(mcdfilenames),1);

for imcd=1:numel(mcdfilenames)
    mcdpathname = [mcdpath,filesep,mcdfilenames{imcd}]; %get mcd path
    [nsresult, hfile] = mexprog(1, mcdpathname); %open file
    [nsresult, mcdfileInfo] = mexprog(3, hfile); %get file info
    totalsamples(imcd)=mcdfileInfo.TimeSpan/mcdfileInfo.TimeStampResolution;
    nsresult = mexprog(14, hfile); clear hfile; %close file
end
clear mexprog; %unload DLL
%--------------------------------------------------------------------------
end