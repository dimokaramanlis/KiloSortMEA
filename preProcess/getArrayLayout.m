function [arrLt] = getArrayLayout(mcdpath)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%--------------------------------------------------------------------------    
[dllpath,libtoload] = getMCSdllPath();
% first open the dll file
nsresult=mexprog(18, [dllpath, filesep, libtoload]);  %ok   % ns_SetLibrary
% opening file
mcdfilenames = dir([mcdpath,filesep,'*.mcd']);
[~, hfile] = mexprog(1, [mcdpath,filesep,mcdfilenames(1).name]);  %ok% ns_OpenFile
% get the info from the file
[~, mcdfileInfo] = mexprog(3, hfile); %ns_GetFileInfo
arrLt.Nchannels=mcdfileInfo.EntityCount;
arrLt.fs = 1/mcdfileInfo.TimeStampResolution; % sampling frequency
% get channel names and data in each channel
[~, chinfos] = mexprog(4, hfile,0:mcdfileInfo.EntityCount-1); %ns_GetEntityInfo
% Close data file. Should be done by the library but just in case.
nsresult=mexprog(14, hfile); clear mexprog; %ns_CloseFile and unload DLL
%--------------------------------------------------------------------------    
% get the channel names based on the map of the array

% extract labels of the entities. Something like 'digi0001 0063 0000       D1'
labellist = {chinfos.EntityLabel}; 
anlg=find(contains(labellist,'anlg0001'));
connected=~ismember(1:numel(labellist),anlg);
chnames = regexprep(extractAfter(labellist,'      '), '\s+', '')';
R = cell2mat(regexp(chnames,'(?<Name>\D+)(?<Nums>\d+)','names'));
namesCell=[{R.Name}' {R.Nums}'];
namesCell(~connected,:)=[{'A'} {'1'}; {'A'} {'16'};{'R'} {'1'};{'R'} {'16'}];
[~,chmeaidx] = sortrows([namesCell(:,1) num2cell(cellfun(@(x)str2double(x),namesCell(:,2)))]);        
%--------------------------------------------------------------------------
%get basic info
arrLt.chMap=chmeaidx';
arrLt.chanMap0ind = arrLt.chMap - 1;
arrLt.connected=~ismember(chmeaidx,anlg);
%get geometry
xmax=16; ymax=16; elDist=100;
[xcoords,ycoords]=meshgrid(0:1:xmax-1, ymax-1:-1:0);
xcoords = elDist * xcoords(:); xcoords(~arrLt.connected)=NaN;
ycoords = elDist * ycoords(:); ycoords(~arrLt.connected)=NaN;
arrLt.xcoords=xcoords; arrLt.ycoords=ycoords;
%everything is in the same shaft
kcoords = ones(arrLt.Nchannels,1); kcoords(~arrLt.connected)=NaN;
arrLt.kcoords=kcoords;
%--------------------------------------------------------------------------   
end

