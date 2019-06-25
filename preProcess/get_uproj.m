function [uproj] = get_uproj(rez,DATA)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

ops = rez.ops;
Nchan = ops.Nchan;
Nbatch      = rez.temp.Nbatch;
Nbatch_buff = rez.temp.Nbatch_buff;

NT  	= ops.NT;
batchstart = 0:NT:NT*Nbatch;
wPCA = ops.wPCA;

uproj = zeros(4e6,  size(wPCA,2) * Nchan, 'single');

fid = fopen(ops.fproc, 'r');

i0 = 0;

for ibatch = 1:ops.nskip:Nbatch
    if ibatch>Nbatch_buff
        offset = 2 * ops.Nchan*batchstart(ibatch-Nbatch_buff);
        fseek(fid, offset, 'bof');
        dat = fread(fid, [NT ops.Nchan], '*int16');
    else
        dat = DATA(:,:,ibatch);
    end
    % move data to GPU and scale it
    if ops.GPU
        dataRAW = gpuArray(dat);
    else
        dataRAW = dat;
    end
    dataRAW = single(dataRAW);
    dataRAW = dataRAW / ops.scaleproc;
    
    % find isolated spikes
    [row, col, mu] = isolated_peaks_new(dataRAW, ops);
    
    % find their PC projections
    uS = get_PCproj(dataRAW, row, col, wPCA, ops.maskMaxChannels,ops.nt0min);
    uS = permute(uS, [2 1 3]);
    uS = reshape(uS,numel(row), Nchan * size(wPCA,2));
    
    if i0+numel(row)>size(uproj,1)
        uproj(2e6 + size(uproj,1), 1) = 0;
    end
    
    uproj(i0 + (1:numel(row)), :) = gather_try(uS);
    i0 = i0 + numel(row);
    
end
fclose(fid);

uproj(i0+1:end, :) = [];

        
end

