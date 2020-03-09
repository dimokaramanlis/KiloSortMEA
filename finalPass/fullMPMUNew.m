function rez = fullMPMUNew(rez)

ops = rez.ops;

Nfilt   = ops.Nfilt;
lam =  ones(Nfilt, 1, 'single');
lam(:)    = ops.lam(3);

[W, U, mu, UtU, nu] = decompose_dWU(ops, rez.dWU, ops.Nrank,rez.ops.kcoords);


pm = exp(-ops.momentum(2));
Params = double([ops.NT ops.Nfilt ops.Th(3) ops.maxFR 10 ops.Nchan ops.Nrank pm ops.epu ops.nt0]);

Params(3) = ops.Th(3);
Params(4) = 50000;
Params(5) = 50; 

U0 = gpuArray(U);

%%
nt0     = rez.ops.nt0;
Nrank   = ops.Nrank;
WtW     = zeros(Nfilt,Nfilt,2*nt0-1, 'single');
for i = 1:Nrank
    for j = 1:Nrank
        utu0 = U0(:,:,i)' * U0(:,:,j);
        wtw0 =  gather_try(mexWtW2(Params, W(:,:,i), W(:,:,j), utu0));
        WtW = WtW + wtw0;
        clear wtw0 utu0        
    end
end

mWtW = max(WtW, [], 3);
WtW = permute(WtW, [3 1 2]);

WtW = gpuArray(WtW);

Nbatch      = rez.temp.Nbatch;
Nchan       = ops.Nchan;

clear wtw0 utu0 U0;

st3 = [];
rez.st3 = [];

if ops.verbose
   fprintf('Time %3.0f min. Running the final template matching pass...\n', toc/60) 
end

%==========================================================================
nNeigh    = ops.nNeigh;

%initialize for 50 million spikes
rez.cProj = zeros(50e6, nNeigh, 'single'); %zeros(5e6, nNeigh, 'single');

% sort pairwise templates
nsp = sum(rez.nspikes,2);
vld = single(nsp>100);
cr    = mWtW .* (vld * vld');
cr(isnan(cr)) = 0;
[~, iNgsort] = sort(cr, 1, 'descend');

% save full similarity score
rez.simScore = cr;
maskTT = zeros(Nfilt, 'single');
rez.iNeigh = iNgsort(1:nNeigh, :);
for i = 1:Nfilt
    maskTT(rez.iNeigh(:,i),i) = 1;
end
%==========================================================================
% prepare pcs 

nNeighPC  = ops.nNeighPC;
Wi=ops.wPCA; %load PCspikes;
ixt = round(linspace(1, size(Wi,1), ops.nt0));
Wi = Wi(ixt, 1:3);
%initialize for 50 million spikes
rez.cProjPC = zeros(50e6, 3*nNeighPC, 'single'); 

% sort best channels
[~, iNch]       = sort(abs(U(:,:,1)), 1, 'descend');
maskPC          = zeros(Nchan, Nfilt, 'single');
rez.iNeighPC    = iNch(1:nNeighPC, :);
for i = 1:Nfilt
    maskPC(rez.iNeighPC(:,i),i) = 1;
end
maskPC = repmat(maskPC, 3, 1);
%==========================================================================

fid = fopen(ops.fproc, 'r'); % open file
msg = [];

irun = 0;
i1nt0 = int32(1:nt0)';

LAM = lam .* (20./mu).^2;

NT = ops.NT;
batchstart = 0:NT:NT*Nbatch;

for ibatch = 1:Nbatch    
    
    offset = 2 * ops.Nchan*batchstart(ibatch); % - ioffset;
    fseek(fid, offset, 'bof');
    dat = fread(fid, [NT ops.Nchan], '*int16');

    dataRAW = gpuArray(dat);
    dataRAW = single(dataRAW);
    dataRAW = dataRAW / ops.scaleproc;
    
    % project data in low-dim space
    data    = gpuArray.zeros(NT, Nfilt, Nrank, 'single');

    for irank = 1:Nrank
        data(:,:,irank) = dataRAW * U(:,:,irank);
    end
    data                = reshape(data, NT, Nfilt*Nrank);

    % main CUDA code
    [st, id, x, errC, PCproj] = mexMPmuFEAT(Params,data,W,WtW, mu, lam .* (20./mu).^2, nu);
 
    if ~isempty(st)
        if ~isempty(ops.nNeighPC)
            % PCA coefficients
            inds            = repmat(st', nt0, 1) + repmat(i1nt0, 1, numel(st));
            try  datSp      = dataRAW(inds(:), :);
            catch
                datSp       = dataRAW(inds(:), :);
            end
            datSp           = reshape(datSp, [size(inds) Nchan]);
            coefs           = reshape(Wi' * reshape(datSp, nt0, []), size(Wi,2), numel(st), Nchan);
            coefs           = reshape(permute(coefs, [3 1 2]), [], numel(st));
            coefs           = coefs .* maskPC(:, id+1);
            iCoefs          = reshape(find(maskPC(:, id+1)>0), 3*nNeighPC, []);
            
            if irun+numel(st)>size(rez.cProjPC,1)
                rez.cProjPC(10e6 + size(rez.cProjPC,1), 1) = 0; %add ten million spike places if needed
            end
            
            rez.cProjPC(irun + (1:numel(st)), :) = gather_try(coefs(iCoefs)');
        end
        if ~isempty(ops.nNeigh)
            % template coefficients
            % transform coefficients
            PCproj          = bsxfun(@rdivide, ...
                bsxfun(@plus, PCproj, LAM.*mu), sqrt(1+LAM));
            
            PCproj          = maskTT(:, id+1) .* PCproj;
            iPP             = reshape(find(maskTT(:, id+1)>0), nNeigh, []);
            
            if irun+numel(st)>size(rez.cProj,1)
                rez.cProj(10e6 + size(rez.cProj,1), 1) = 0; %add ten million spike places if needed
            end
            
            rez.cProj(irun + (1:numel(st)), :) = PCproj(iPP)';
        end
        % increment number of spikes
        irun            = irun + numel(st);
        
        if ibatch==1
            ioffset         = 0;
        else
            ioffset         = ops.ntbuff;
        end
        st                  = st - ioffset;
        
        STT = cat(2, ops.nt0min + double(st) +(NT-ops.ntbuff)*(ibatch-1), ...
            double(id)+1, double(x), ibatch*ones(numel(x),1));
        st3             = cat(1, st3, STT);
    end
    
    % print message
    if ops.verbose && (rem(ibatch, 500) ==1 || ibatch == Nbatch)
        % fprintf(repmat('\b', 1, numel(msg)));
        msg             = sprintf('Time %2.0f min, batch %d/%d,  NTOT %d\n', ...
            toc/60, ibatch,Nbatch, size(st3,1));        
        fprintf(msg);
    end
    
end
fclose(fid); %close the data file

% sort spikes
[~, isort]      = sort(st3(:,1), 'ascend');
st3             = st3(isort,:);
rez.st3         = st3;

% sort features and principal components

rez.cProj  (irun+1:end, :) = [];
rez.cProjPC(irun+1:end, :) = [];

rez.cProj                   = rez.cProj(isort, :);

rez.cProjPC                 = reshape(rez.cProjPC, size(rez.cProjPC,1), [], 3);
rez.cProjPC                 = rez.cProjPC(isort, :,:);

% re-index the template and projection coefficients
for ik = 1:Nfilt
    iSp                     = rez.st3(:,2)==ik;
    
    OneToNfeat              = 1:nNeigh;
    [~, isortNeigh]         = sort(rez.iNeigh(:,ik), 'ascend');
    OneToNfeat(isortNeigh)  = OneToNfeat;
    rez.cProj(iSp, :)       = rez.cProj(iSp, OneToNfeat);
    
    OneToNpc                = 1:nNeighPC;
    [~, isortNeigh]         = sort(rez.iNeighPC(:,ik), 'ascend');
    OneToNpc(isortNeigh)    = OneToNpc;
    rez.cProjPC(iSp, :,:)   = rez.cProjPC(iSp, OneToNpc, :);
    
end

rez.cProjPC                 = permute(rez.cProjPC, [1 3 2]);

%%
% rez.ops             = ops;
rez.W               = W;
rez.U               = U;
rez.mu              = mu;

rez.t2p = [];
for i = 1:Nfilt
    wav0            = W(:,i,1);
    wav0            = my_conv(wav0', .5)';
   [~, itrough]     = min(wav0);
    [~, t2p]        = max(wav0(itrough:end));
    rez.t2p(i,1)    = t2p;
    rez.t2p(i,2)    = itrough;   
end

rez.nbins           = histc(rez.st3(:,2), .5:1:Nfilt+1);
[~, rez.ypos]       = max(rez.U(:,:,1), [], 1);

% center the templates for phy
rez.W               = cat(1, zeros(ops.nt0 - 2*ops.nt0min - 1, Nfilt, Nrank), rez.W);
rez.WrotInv         = (rez.Wrot/ops.scaleproc)^-1;
%%
Urot = U;
for k = 1:size(U,3)
   Urot(:,:,k)  = rez.WrotInv' * Urot(:,:,k);
end
for n = 1:size(U,2)
    rez.Wraw(:,:,n) = mu(n) * sq(Urot(:,n,:)) * sq(rez.W(:,n,:))';
end

if ops.verbose
   fprintf('Time %3.0f min. Sorting is done!\n', toc/60) 
end
