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
stimsamples=zeros(numel(h5filenames),1);
for imcd=1:numel(h5filenames)
    h5pathname = [ops.root,filesep,h5filenames{imcd}]; %get mcd path
    stimdata{imcd} = McsHDF5.McsData(h5pathname,cfg);
    stimsamples(imcd) = size(stimdata{imcd}.Recording{1}.AnalogStream{1}.ChannelDataTimeStamps,2); 
end
bininfo.stimsamples = stimsamples;

H5fileInfo = stimdata{imcd}.Recording{1}.AnalogStream{1}.Info;
NchanTOT = size(H5fileInfo.ChannelID,1);
bininfo.NchanTOT = NchanTOT;
fs = stimdata{imcd}.Recording{1}.AnalogStream{2}.getSamplingRate;  % sampling frequency
bininfo.fs = fs;
fprintf('Total length of recording is %2.2f min...\n',sum(stimsamples)/fs/60);
%--------------------------------------------------------------------------
% get the channel names based on the map of the array
labellist = {H5fileInfo.Label};
chanMap = getChannelMapForRawBinary(labellist,'dataformat','msrd','channelnumber',NchanTOT);
%--------------------------------------------------------------------------
fprintf('Saving .mcd data as .dat...\n');
% chunk size
maxSamples=64e5;

fidOut= fopen(targetpath, 'W'); %using W (capital), makes writing ~4x faster

for iFile=1:Nfiles
    
    h5dat = stimdata{iFile}.Recording{1}.AnalogStream{1};
    nsamples = stimsamples(iFile);
    Nchunk = ceil(nsamples/maxSamples);
    
    for iChunk=1:Nchunk
        offset = max(0, (maxSamples * (iChunk-1)));
        sampstoload=min(nsamples-offset,maxSamples);       
        %         cfg = McsHDF5.checkParameter(cfg, 'window', McsHDF5.TickToSec([h5dat.ChannelDataTimeStamps(1) ...
        %                       h5dat.ChannelDataTimeStamps(end)]));
        %     start_index = find(analogStream.ChannelDataTimeStamps >= McsHDF5.SecToTick(cfg.window(1)),1,'first');
        %     end_index = find(analogStream.ChannelDataTimeStamps <= McsHDF5.SecToTick(cfg.window(2)),1,'last');
        %
        %
        %   cfg.channel = [5 15]; % channel index 5 to 15
        cfg.window = double([h5dat.ChannelDataTimeStamps(offset+1) h5dat.ChannelDataTimeStamps(offset+sampstoload)]) / 1e6;
        % to convert from microseconds to sec for more info check McsHDF5.TickToSec
        
        dat = h5dat.readPartialChannelData(cfg);
        %         orig_exp = log10(max(abs(dat.ChannelData(:))));
        %         unit_exp = double(h5dat.Info.Exponent(1));
        %         multFact = McsHDF5.ExponentToUnit(orig_exp+unit_exp,orig_exp);
        %converted_data = double(dat.ChannelData) * multFact;
        %         d = h5dat.getConvertedData(cfg);
        %         converted_data = (double(dat.ChannelData) - double(h5dat.Info.ADZero(1))) / double(h5dat.Info.ConversionFactor(1));
        
        dat = int16(dat.ChannelData(chanMap + 1,:));
        %         nsampcurr=size(dat,2);
        %         if nsampcurr<sampstoload
        %             dat(:,nsampcurr+1:int64(sampstoload))=repmat(dat(:,nsampcurr),...
        %                 1,int64(sampstoload)-nsampcurr);
        %         end
        fwrite(fidOut, dat, 'int16');
    end
    
    %report status
    fprintf('Time %3.0f min. Mcd files processed %d/%d \n',toc/60, iFile,Nfiles);
end
fclose(fidOut);
%--------------------------------------------------------------------------
end
