function [ops] = convertMcdToRawBinaryCAR(ops)
%CONVERTMCDTORAWBINARYCAR Save mcd files as binary without analog channels
% 
%--------------------------------------------------------------------------
%figure out inputs
if nargin<2; filename='alldata.dat'; end
%--------------------------------------------------------------------------
[stimsamples]=getExperimentLength(ops.root);
Nsamps=sum(stimsamples);
arrLt=getArrayLayout(mcdpath); %try to fix this part
[~,sortedId]=sort(arrLt.chMap); %try to fix this part
channelsToRead=find(arrLt.connected(sortedId));
fprintf('Total length of recording is %2.2f min...\n',sum(stimsamples)/arrLt.fs/60);
%--------------------------------------------------------------------------
%allocate batch size
chunkSize=3600000; %6 min for 10kHz fs, change if out of memory
Nchunks=ceil(Nsamps/chunkSize);
%--------------------------------------------------------------------------
fprintf('Saving .mcd data as .dat after common average referencing...\n');

medianTrace = zeros(Nchunks, chunkSize,'int16');

fidOut= fopen(fullfile(ops.root,filename), 'W'); %using W (capital), makes writing ~4x faster
msg=[];
for iChunk=1:Nchunks
    
    offset = max(0, (chunkSize * (iChunk-1)));
    dat=readMcdData(mcdpath,stimsamples,channelsToRead,offset+1,chunkSize);
    
    dat = bsxfun(@minus, dat, median(dat,2)); % subtract median of each channel
    tm = median(dat,1);
    dat = bsxfun(@minus, dat, tm); % subtract median of each time point
    fwrite(fidOut, dat, 'int16');
    
    medianTrace(iChunk,1:numel(tm))=tm;
    %report status
    fprintf(repmat('\b', 1, numel(msg)));
    msg=sprintf('chunk %d/%d \n',iChunk,Nchunks); fprintf(msg);
end
fclose(fidOut);
save([ops.root filesep 'medianCAR.mat'], 'medianTrace', '-v7.3');

end