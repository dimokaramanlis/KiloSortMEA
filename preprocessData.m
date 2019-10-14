function [rez, DATA] = preprocessData(ops)
tic;

ops.nt0 	= getOr(ops, {'nt0'}, 61);
ops.filter 	= getOr(ops, {'filter'}, true);

if ~isempty(ops.chanMap)
    if ischar(ops.chanMap)
        load(ops.chanMap);
        try
            chanMapConn = chanMap(connected>1e-6);
            xc = xcoords(connected>1e-6);
            yc = ycoords(connected>1e-6);
        catch
            chanMapConn = 1+chanNums(connected>1e-6);
            xc = zeros(numel(chanMapConn), 1);
            yc = [1:1:numel(chanMapConn)]';
        end
        ops.Nchan    = getOr(ops, 'Nchan', sum(connected>1e-6));
        ops.NchanTOT = getOr(ops, 'NchanTOT', numel(connected));
        if exist('fs', 'var')
            ops.fs       = getOr(ops, 'fs', fs);
        end
    else
        chanMap = ops.chanMap;
        chanMapConn = ops.chanMap;
        xc = zeros(numel(chanMapConn), 1);
        yc = [1:1:numel(chanMapConn)]';
        connected = true(numel(chanMap), 1);      
        
        ops.Nchan    = numel(connected);
        ops.NchanTOT = numel(connected);
    end
else
    chanMap  = 1:ops.Nchan;
    connected = true(numel(chanMap), 1);
    
    chanMapConn = 1:ops.Nchan;    
    xc = zeros(numel(chanMapConn), 1);
    yc = [1:1:numel(chanMapConn)]';
end
if exist('kcoords', 'var')
    kcoords = kcoords(connected);
else
    kcoords = ones(ops.Nchan, 1);
end
NchanTOT = ops.NchanTOT;
NT       = ops.NT ;

rez.ops = ops;
rez.xc = xc; rez.yc = yc;
if exist('xcoords','var')
   rez.xcoords = xcoords; rez.ycoords = ycoords;
else
   rez.xcoords = xc; rez.ycoords = yc;
end
rez.connected   = connected;
rez.ops.chanMap = chanMap;
rez.ops.kcoords = kcoords; 

d = dir(ops.fbinary);
ops.sampsToRead = floor(d.bytes/NchanTOT/2);

if ispc
    dmem         = memory;
    memfree      = dmem.MemAvailableAllArrays/8;
    memallocated = min(ops.ForceMaxRAMforDat, dmem.MemAvailableAllArrays) - memfree;
    memallocated = max(0, memallocated);
else
    memallocated = ops.ForceMaxRAMforDat;
end
nint16s      = memallocated/2;
NTbuff      = NT + 4*ops.ntbuff;
Nbatch      = ceil(d.bytes/2/NchanTOT /(NT-ops.ntbuff));
Nbatch_buff = floor(4/5 * nint16s/rez.ops.Nchan /(NT-ops.ntbuff)); % factor of 4/5 for storing PCs of spikes
Nbatch_buff = min(Nbatch_buff, Nbatch);
%% load data into patches, filter, compute covariance
if isfield(ops,'fslow')&&ops.fslow<ops.fs/2 && ops.filter
    [b1, a1] = butter(3, [ops.fshigh/ops.fs,ops.fslow/ops.fs]*2, 'bandpass');
else
    [b1, a1] = butter(3, ops.fshigh/ops.fs*2, 'high');
end

fprintf('Time %3.0f min. Loading raw data... \n', toc/60);
fid = fopen(ops.fbinary, 'r');
ibatch = 0;
Nchan = rez.ops.Nchan;
if ops.GPU
    CC = gpuArray.zeros( Nchan,  Nchan, 'single');
else
    CC = zeros( Nchan,  Nchan, 'single');
end
if strcmp(ops.whitening, 'noSpikes')
    if ops.GPU
        nPairs = gpuArray.zeros( Nchan,  Nchan, 'single');
    else
        nPairs = zeros( Nchan,  Nchan, 'single');
    end
end
if ~exist('DATA', 'var')
    DATA = zeros(NT, rez.ops.Nchan, Nbatch_buff, 'int16');
end

isproc = zeros(Nbatch, 1);
while 1
    ibatch = ibatch + ops.nSkipCov;
    
    offset = max(0, 2*NchanTOT*((NT - ops.ntbuff) * (ibatch-1) - 2*ops.ntbuff));
    if ibatch==1; ioffset = 0; else; ioffset = ops.ntbuff; end
    
    %read data
    fseek(fid, offset, 'bof');
    buff = fread(fid, [NchanTOT NTbuff], '*int16');
    if isempty(buff); break; end

    nsampcurr = size(buff,2);
    if nsampcurr<NTbuff
        buff(:, nsampcurr+1:NTbuff) = repmat(buff(:,nsampcurr), 1, NTbuff-nsampcurr);
    end
    
    if ops.GPU; dataRAW = gpuArray(buff); else; dataRAW = buff; end
    
    dataRAW = dataRAW';
    dataRAW = single(dataRAW);
    dataRAW = dataRAW(:, chanMapConn);
    
    % subtract the mean from each channel
    dataRAW = dataRAW - mean(dataRAW, 1);    
    
    if ops.filter
        datr = filter(b1, a1, dataRAW);
        datr = flipud(datr);
        datr = filter(b1, a1, datr);
        datr = flipud(datr);
    else
        datr=dataRAW;
    end
    
      % CAR, common average referencing by median
    if getOr(ops, 'CAR', 1)
        datr = datr - median(datr, 2);
    end
    
    
    switch ops.whitening
        case 'noSpikes'
            smin      = my_min(datr, ops.loc_range, [1 2]);
            %sd = std(datr, [], 1);
            sd = mad(datr,1,1);
            peaks     = single(datr<smin+1e-3 & bsxfun(@lt, datr, ops.spkTh * sd));
            blankout  = 1+my_min(-peaks, ops.long_range, [1 2]);
            smin      = datr .* blankout;
            CC        = CC + (smin' * smin)/NT;
            nPairs    = nPairs + (blankout'*blankout)/NT;
        otherwise
            CC        = CC + (datr' * datr)/NT;
    end
    
    if ibatch<=Nbatch_buff
        DATA(:,:,ibatch) = gather_try(int16( datr(ioffset + (1:NT),:)));
        isproc(ibatch) = 1;
    end
end
CC = CC / ceil((Nbatch-1)/ops.nSkipCov);
switch ops.whitening
    case 'noSpikes'; nPairs = nPairs/ibatch;
end
fclose(fid);

fprintf('Time %3.0f min. Channel-whitening filters computed. \n', toc/60);

switch ops.whitening
    case 'diag'; CC = diag(diag(CC));
    case 'noSpikes'; CC = CC ./nPairs;
end

if ops.whiteningRange<Inf
    ops.whiteningRange = min(ops.whiteningRange, Nchan);
    Wrot = whiteningLocal(gather_try(CC), yc, xc, ops.whiteningRange);
else
    [E, D] 	= svd(CC);
    D = diag(D);
    eps 	= 1e-6;
    Wrot 	= E * diag(1./(D + eps).^.5) * E';
end
Wrot    = ops.scaleproc * Wrot;

fprintf('Time %3.0f min. Loading raw data and applying filters... \n', toc/60);

fid         = fopen(ops.fbinary, 'r');
if Nbatch_buff<Nbatch; fidW    = fopen(ops.fproc, 'W'); end


msg=[];
for ibatch = 1:Nbatch
    if isproc(ibatch) %ibatch<=Nbatch_buff
        if ops.GPU
            datr = single(gpuArray(DATA(:,:,ibatch)));
        else
            datr = single(DATA(:,:,ibatch));
        end
    else
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
        dataRAW = dataRAW(:, chanMapConn);
        
        % subtract the mean from each channel
        dataRAW = dataRAW - mean(dataRAW, 1);   
        
        if ops.filter
            datr = filter(b1, a1, dataRAW); datr = flipud(datr);
            datr = filter(b1, a1, datr); datr = flipud(datr);
        else
            datr=dataRAW;
        end
        
        % CAR, common average referencing by median
        if getOr(ops, 'CAR', 1)
            datr = datr - median(datr, 2);
        end
    
        datr = datr(ioffset + (1:NT),:);
    end
    
    datr    = datr * Wrot;
    
    if ibatch<=Nbatch_buff
        DATA(:,:,ibatch) = gather_try(datr);
    else
        datcpu  = gather_try(int16(datr));
        fwrite(fidW, datcpu, 'int16');
    end
    
    % update status
    if ops.verbose && rem(ibatch,100)==1
        fprintf(repmat('\b', 1, numel(msg)));
        msg = sprintf('Time %2.0f min, batch %d/%d\n',toc/60, ibatch,Nbatch);
        fprintf(msg);
    end
end
fclose(fid);
if Nbatch_buff<Nbatch; fclose(fidW); end

Wrot = gather_try(Wrot); rez.Wrot = Wrot;

if ops.verbose
    fprintf('Time %2.0f min. Whitened data written to disk... \n', toc/60);
    fprintf('Time %2.0f min. Preprocessing complete!\n', toc/60);
end

rez.temp.Nbatch = Nbatch; rez.temp.Nbatch_buff = Nbatch_buff;