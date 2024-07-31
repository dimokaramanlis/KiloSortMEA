function cProjPC = calculatePrincipalComponents(rez)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


Wi=rez.ops.wPCA; %load PCspikes;
Nchan = rez.ops.Nchan;
nt0 = rez.ops.nt0;
dt =-rez.ops.nt0min + (1:nt0);
Nbatch      = rez.ops.Nbatch;
NT  	= rez.ops.NT;
Nfilt  = size(rez.dWU,3);
batchstart = 0:NT:NT*Nbatch;    

cProjPC = NaN(size(rez.st3,1), 3, rez.ops.nNeighPC,'single');

fid = fopen(rez.ops.fproc, 'r');

fprintf('Extracting principal compoments... '); msg = [];

for ibatch = 1:Nbatch


    offset = 2 * Nchan*batchstart(ibatch);
    fseek(fid, offset, 'bof');
    dat = fread(fid, [NT Nchan], '*int16');
    % move data to GPU and scale it
    dat = double(gpuArray(dat));
    dat = dat / rez.ops.scaleproc;
    
    if ibatch == 1
        ioffset = 0;
    else
        ioffset= rez.ops.ntbuff;
    end
    stmin = (NT-rez.ops.ntbuff)*(ibatch-1) - ioffset;
    stmax = stmin + NT;

    currid = rez.st3(:,1)>stmin & rez.st3(:,1)<stmax;
    stcurr = rez.st3(currid,:);

    stimescurr = stcurr(:,1) - stmin;
    irem = stimescurr+max(dt) > NT | stimescurr + min(dt) <1;
    stcurr(irem, :) = [];
    stimescurr(irem) = [];
    
    gpucurr = gpuArray.zeros([numel(stimescurr), 3, rez.ops.nNeighPC],'single');
    for ii = 1:numel(dt)
        cinds = sub2ind([size(dat,1) Nchan],repmat(stimescurr + dt(ii),1,16),rez.iNeighPC(:,stcurr(:,2))');
        gpuadd = reshape(dat(cinds), [numel(stimescurr)*16,1]) * Wi(ii,:);
        gpucurr = gpucurr + reshape(gpuadd, size(gpucurr));
    end
    spreplace = find(currid);
    spreplace(irem) = [];
    cProjPC(spreplace, :,:) = gather(gpucurr);
    
    % print message
    if rez.ops.verbose
    fprintf(repmat('\b', 1, numel(msg)));
    msg             = sprintf('Time %2.0f min, batch %d/%d \n', ...
        toc/60, ibatch,Nbatch);        
    fprintf(msg);
    end

end
fclose(fid);


%find NaNs
toreplace = find(isnan(cProjPC(:,1,1)));

if isempty(toreplace)
    return;
else
    aa = 1;
end


end