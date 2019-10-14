function [rez] = preprocessDataNew(ops)
tic;

ops.nt0 	= getOr(ops, {'nt0'}, 61);
ops.filter 	= getOr(ops, {'filter'}, true);




NT       = ops.NT ;
NchanTOT = ops.NchanTOT;
NTbuff      = NT + 4*ops.ntbuff;

bytes = get_file_size(ops.fbinary);
ops.sampsToRead = floor(bytes/NchanTOT/2);
Nbatch      = ceil(ops.sampsToRead /(NT-ops.ntbuff));
ops.Nbatch = Nbatch;

[chanMap, xc, yc, kcoords, NchanTOTdefault] = loadChanMap(ops.chanMap);
ops.NchanTOT = getOr(ops, 'NchanTOT', NchanTOTdefault);

if getOr(ops, 'minfr_goodchannels', .1)>0
    
    % determine bad channels
    fprintf('Time %3.0fs. Determining good channels.. \n', toc);

    igood = get_good_channels(ops, chanMap);
    xc = xc(igood);
    yc = yc(igood);
    kcoords = kcoords(igood);
    chanMap = chanMap(igood);
        
    ops.igood = igood;
else
    ops.igood = true(size(chanMap));
end


ops.Nchan = numel(chanMap);
ops.Nfilt = floor(getOr(ops, 'nfilt_factor', 6.5) * ops.Nchan /32)*32;

rez.ops         = ops;
rez.xc = xc;
rez.yc = yc;

rez.xcoords = xc;
rez.ycoords = yc;

% rez.connected   = connected;
rez.ops.chanMap = chanMap;
rez.ops.kcoords = kcoords; 

% by how many bytes to offset all the batches
rez.ops.Nbatch = Nbatch;
rez.ops.NTbuff = NTbuff;
rez.ops.chanMap = chanMap;

fprintf('Time %3.0fs. Computing whitening matrix.. \n', toc);

% this requires removing bad channels first
Wrot = get_whitening_matrix(rez);

fprintf('Time %3.0f min. Loading raw data and applying filters... \n', toc/60);

fid     = fopen(ops.fbinary, 'r');
fidW    = fopen(ops.fproc, 'W');


msg=[];
for ibatch = 1:Nbatch

    offset = max(0, 2*NchanTOT*((NT - ops.ntbuff) * (ibatch-1) - 2*ops.ntbuff));
    if ibatch==1; ioffset = 0; else, ioffset = ops.ntbuff; end

    %read data
    fseek(fid, offset, 'bof');
    buff = fread(fid, [NchanTOT NTbuff], '*int16');
    if isempty(buff); break; end

    nsampcurr = size(buff,2);
    if nsampcurr<NTbuff
        buff(:, nsampcurr+1:NTbuff) = repmat(buff(:,nsampcurr), 1, NTbuff-nsampcurr);
    end

    if ops.GPU
        dataRAW = gpuArray(buff);
    else
        dataRAW = buff;
    end

    dataRAW = dataRAW';
    dataRAW = single(dataRAW);
    dataRAW = dataRAW(:, chanMap);

    
    % subtract the mean from each channel
    dataRAW = dataRAW - mean(dataRAW, 1);   
    
    % CAR, common average referencing by median
    if getOr(ops, 'CAR', 1)
        dataRAW = dataRAW - median(dataRAW, 2);
    end
    
    if ops.filter
        datr = filter(b1, a1, dataRAW);
        datr = flipud(datr);
        datr = filter(b1, a1, datr);
        datr = flipud(datr);
    else
        datr = dataRAW;
    end

    datr = datr(ioffset + (1:NT),:);
    
    datr    = datr * Wrot;
    
    
    datcpu  = gather_try(int16(datr));
    fwrite(fidW, datcpu, 'int16');
    
    % update status
    if ops.verbose && rem(ibatch,100)==1
        fprintf(repmat('\b', 1, numel(msg)));
        msg = sprintf('Time %2.0f min, batch %d/%d\n',toc/60, ibatch,Nbatch);
        fprintf(msg);
    end
end
fclose(fid);
fclose(fidW); 

Wrot = gather_try(Wrot); rez.Wrot = Wrot;

if ops.verbose
    fprintf('Time %2.0f min. Whitened data written to disk... \n', toc/60);
    fprintf('Time %2.0f min. Preprocessing complete!\n', toc/60);
end

rez.temp.Nbatch = Nbatch;