function [bininfo] = convertMsrdH5ToRawBinary(ops, targetpath)

% status = system('"Multi Channel DataManager.exe" &')
% status = system('set PATH=' 'C:\Program Files\ Multi Channel DataManager' ' && ''Multi Channel DataManager.exe &');
% status = system('set path=%path:"C:\Program Files\Multi Channel DataManager\";=% & "Multi Channel DataManager.exe" &');
% dataHFfilename = '2019-05-21T18-13-48HippocampalCultures_ControlReal_spontaneous.h5';
% cfg = [];
% % cfg.dataType = 'single';
% cfg.dataType = 'raw';
% data = McsHDF5.McsData([datapath,'/',dataHFfilename],cfg);
% %%
% % One can convert data loaded with the 'raw' option to meaningful units
% % either manually (in this example for the first channel of an analog stream):
% %
% % converted_data = (data.Recording{1}.AnalogStream{1}.ChannelData(1,:) - ...
% %     double(data.Recording{1}.AnalogStream{1}.Info.ADZero(1))) * ...
% %     double(data.Recording{1}.AnalogStream{1}.Info.ConversionFactor(1));
%
%
% raw_data = data.Recording{1}.AnalogStream{1}.getConvertedData(cfg);
% filtered_data = data.Recording{1}.AnalogStream{2}.getConvertedData(cfg);
% samplerate = data.Recording{1}.AnalogStream{2}.getSamplingRate;

%--------------------------------------------------------------------------
tic;
% get msrd filenames
h5filenames = dir([ops.root,filesep,'*.h5']);
[~, reindex]=sort(str2double(regexp(({h5filenames(:).name}),'\d+','match','once')));
h5filenames={h5filenames(reindex).name}'; Nfiles=numel(h5filenames);
%--------------------------------------------------------------------------
% get information about the recording time
% config files for dataloading
cfg = [];
cfg.dataType = 'raw';

stimdata = cell(numel(h5filenames),1);

for imcd=1:numel(h5filenames)
    h5pathname = [ops.root,filesep,h5filenames{imcd}]; %get mcd path
    stimdata{imcd} = McsHDF5.McsData(h5pathname,cfg);
end

streamtype = cell(size(stimdata{imcd}.Recording{1}.AnalogStream));
for ii = 1: size(stimdata{imcd}.Recording{1}.AnalogStream,2)
    streamtype{ii} = stimdata{imcd}.Recording{1}.AnalogStream{ii}.Label;
end
filteredstream = (contains(streamtype,'Filter')); % get only the filtered stream

stimsamples=zeros(numel(h5filenames),1);
for imcd=1:numel(h5filenames)
    stimsamples(imcd) = size(stimdata{imcd}.Recording{1}.AnalogStream{filteredstream}.ChannelDataTimeStamps,2);
end
bininfo.stimsamples = stimsamples;

H5fileInfo = stimdata{imcd}.Recording{1}.AnalogStream{filteredstream}.Info;
NchanTOT = size(H5fileInfo.ChannelID,1);
bininfo.NchanTOT = NchanTOT;
fs = stimdata{imcd}.Recording{1}.AnalogStream{filteredstream}.getSamplingRate;  % sampling frequency
bininfo.fs = fs;
fprintf('Total length of recording is %2.2f min...\n',sum(stimsamples)/fs/60);
%--------------------------------------------------------------------------
% get the channel names based on the map of the array
labellist = {H5fileInfo.Label};
chanMap = getChannelMapForRawBinary(labellist,'dataformat','msrd','channelnumber',NchanTOT);
%--------------------------------------------------------------------------
fprintf('Saving .mcd data as .dat...\n');

maxSamples = 64e5;% chunk size

fidOut = fopen(targetpath, 'W'); %using W (capital), makes writing ~4x faster

for iFile=1:Nfiles
    
    h5dat = stimdata{iFile}.Recording{1}.AnalogStream{filteredstream};
    nsamples = stimsamples(iFile);
    Nchunk = ceil(nsamples/maxSamples);
    
    for iChunk=1:Nchunk
        offset = max(0, (maxSamples * (iChunk-1)));
        sampstoload=min(nsamples-offset,maxSamples);
        lastidxtoload = offset+sampstoload; % added by MHK to avoid end index crashes
        cfg.window = double([h5dat.ChannelDataTimeStamps(offset+1) h5dat.ChannelDataTimeStamps(lastidxtoload)]) / 1e6;
        % to convert from microseconds to sec for more info check McsHDF5.TickToSec
        
        dat = h5dat.readPartialChannelData(cfg);
        dat = int16(dat.ChannelData(chanMap + 1,:));
        fwrite(fidOut, dat, 'int16');
    end
    
    %report status
    fprintf('Time %3.0f min. Mcd files processed %d/%d \n', toc/60, iFile,Nfiles);   
end
fclose(fidOut);
%--------------------------------------------------------------------------
end
