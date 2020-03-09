function rez = fitTemplates(rez)

nt0             = rez.ops.nt0;

fprintf('Time %3.0f min. Extracting 3 PCs from data...\n', toc/60)
wPCA    = extractPCfromSnippets(rez, 3);
rez.ops.wPCA = wPCA;

ops = rez.ops;

rng('default');rng(1);

Nbatch      = rez.temp.Nbatch;

Nfilt 	= ops.Nfilt; %256+128;

ntbuff  = ops.ntbuff;
NT  	= ops.NT;

Nrank   = ops.Nrank;
Th 		= ops.Th;
maxFR 	= ops.maxFR;
muTh	= getOr(ops, {'muTh'}, ops.Th(2));

Nchan 	= ops.Nchan;

batchstart = 0:NT:NT*Nbatch;

delta = NaN * ones(Nbatch, 1);
iperm = randperm(Nbatch);


fprintf('Time %3.0f min. Initializing templates...\n', toc/60)

switch ops.initialize
    case 'fromData'
        uproj  = get_uproj(rez);
        WUinit = optimizePeaks(ops,uproj);%does a scaled kmeans 
        dWU    = WUinit(:,:,1:Nfilt);
        %             dWU = alignWU(dWU);
        clear uproj;
    otherwise
        if ~isempty(getOr(ops, 'initFilePath', [])) && ~getOr(ops, 'saveInitTemps', 0)            
            load(ops.initFilePath);
            dWU = WUinit(:,:,1:Nfilt);
        else
            %initialize_waves0;
            initialize_waves1;
            %initialize_waves2;
            
            ipck = randperm(size(Winit,2), Nfilt);
            W = [];
            U = [];
            for i = 1:Nrank
                W = cat(3, W, Winit(:, ipck)/Nrank);
                U = cat(3, U, Uinit(:, ipck));
            end
            W = alignW(W, ops);
            
            dWU = zeros(nt0, Nchan, Nfilt, 'single');
            for k = 1:Nfilt
                wu = squeeze(W(:,k,:)) * squeeze(U(:,k,:))';
                newnorm = sum(wu(:).^2).^.5;
                W(:,k,:) = W(:,k,:)/newnorm;
                
                dWU(:,:,k) = 10 * wu;
            end
            WUinit = dWU;
        end
end
if getOr(ops, 'saveInitTemps', 0) 
    if ~isempty(getOr(ops, 'initFilePath', [])) 
        save(ops.initFilePath, 'WUinit') 
    else
       warning('cannot save initialization templates because a savepath was not specified in ops.saveInitTemps'); 
    end
end

[W, U, mu, UtU, nu] = decompose_dWU(ops, dWU, Nrank, rez.ops.kcoords);
W0 = W;
W0(NT, 1) = 0;
fW = fft(W0, [], 1);
fW = conj(fW);

nspikes = zeros(Nfilt, Nbatch);
lam =  ones(Nfilt, 1, 'single');

freqUpdate = ops.freqUpdate; %100 * 4;
iUpdate = 1:freqUpdate:Nbatch;


dbins = zeros(100, Nfilt);
dsum = 0;
miniorder = repmat(iperm, 1, ops.nfullpasses);

ii = 1; % first iteration

epu = ops.epu;


%%

pmi = exp(-1./linspace(1/ops.momentum(1), 1/ops.momentum(2), Nbatch*ops.nannealpasses));
Thi  = linspace(ops.Th(1),                 ops.Th(2), Nbatch*ops.nannealpasses);

if ops.lam(1)==0
    lami = linspace(ops.lam(1), ops.lam(2), Nbatch*ops.nannealpasses);
else
    lami = exp(linspace(log(ops.lam(1)), log(ops.lam(2)), Nbatch*ops.nannealpasses));
end

fid = fopen(ops.fproc, 'r');

if ops.showfigures; figure('Position',[200 200 1000 500]); end

nswitch = [0]; msg = [];
fprintf('Time %3.0f min. Optimizing templates ...\n', toc/60)
while (ii<=Nbatch * ops.nfullpasses+1)
    % set the annealing parameters
    if ii<Nbatch*ops.nannealpasses
        Th      = Thi(ii);
        lam(:)  = lami(ii);
        pm      = pmi(ii);
    end
    
    % some of the parameters change with iteration number
    Params = double([NT Nfilt Th maxFR 10 Nchan Nrank pm epu nt0]);
    
    % update the parameters every freqUpdate iterations
    if ii>1 &&  ismember(rem(ii,Nbatch), iUpdate) 
        dWU = gather_try(dWU);
        
        % break bimodal clusters and remove low variance clusters
        if  ops.shuffle_clusters && ii>Nbatch && rem(rem(ii,Nbatch), 4 * freqUpdate)==1   
            [dWU, dbins, nswitch, nspikes, iswitch] = ...
                replace_clusters(dWU, dbins,  Nbatch, ops.mergeT, ops.splitT, WUinit, nspikes, muTh, ops.minSpks);
        end
        
        dWU = alignWU(dWU, ops);
        
        % restrict spikes to their peak group
        %         dWU = decompose_dWU(dWU, kcoords);
        
        % parameter update
        [W, U, mu, UtU, nu] = decompose_dWU(ops, dWU, Nrank, rez.ops.kcoords);
        
        dWU = gpuArray(dWU);

        
        NSP = sum(nspikes,2);
        if ops.showfigures
%             set(0,'DefaultFigureWindowStyle','docked')
%             figure;
            subplot(2,2,1)
            for j = 1:10:Nfilt
                if j+9>Nfilt;
                    j = Nfilt -9;
                end
                plot(log(1+NSP(j + [0:1:9])), mu(j+ [0:1:9]), 'o');
                xlabel('log of number of spikes')
                ylabel('amplitude of template')
                hold all
            end
            axis tight;
            title(sprintf('%d  ', nswitch));
            subplot(2,2,2)
            plot(W(:,:,1))
            title('timecourses of top PC')
            
            subplot(2,2,[3 4])
            imagesc(U(:,:,1))
            title('spatial mask of top PC')
            
            drawnow
        end
        % break if last iteration reached
        if ii>Nbatch * ops.nfullpasses; break; end
        
        % record the error function for this iteration
        rez.errall(ceil(ii/freqUpdate))          = nanmean(delta);
        
    end
    
    % select batch and load from RAM or disk
    ibatch = miniorder(ii);
    offset = 2 * ops.Nchan*batchstart(ibatch);
    fseek(fid, offset, 'bof');
    dat = fread(fid, [NT ops.Nchan], '*int16');
    
    % move data to GPU and scale it
    dataRAW = gpuArray(dat);
    dataRAW = single(dataRAW);
    dataRAW = dataRAW / ops.scaleproc;
    
    % project data in low-dim space
    data = dataRAW * U(:,:);
    
    % run GPU code to get spike times and coefficients
    [dWU, ~, id, x,Cost, nsp] = mexMPregMU(Params,dataRAW,W,data,UtU,mu, lam .* (20./mu).^2, dWU, nu);
    
    dbins = .9975 * dbins;  % this is a hard-coded forgetting factor, needs to become an option
    if ~isempty(id)
        % compute numbers of spikes
        nsp                = gather_try(nsp(:));
        nspikes(:, ibatch) = nsp;
        
        % bin the amplitudes of the spikes
        xround = min(max(1, int32(x)), 100);
        
        dbins(xround + id * size(dbins,1)) = dbins(xround + id * size(dbins,1)) + 1;
        
        % estimate cost function at this time step
        delta(ibatch) = sum(Cost)/1e3;
    end
    
    % update status
    if ops.verbose  && (rem(ii,500)==1 || ii == (Nbatch * ops.nfullpasses))
        nsort = sort(round(sum(nspikes,2)), 'descend');
        %%fprintf(repmat('\b', 1, numel(msg)));
        msg = sprintf('Time %2.0f min, batch %d/%d, mu %2.2f, neg-err %2.2f, NTOT %d, n100 %d, n200 %d, n300 %d, n400 %d\n', ...
            toc/60, ii,Nbatch* ops.nfullpasses,nanmean(mu(:)), nanmean(delta), round(sum(nsort)), ...
            nsort(min(size(W,2), 100)), nsort(min(size(W,2), 200)), ...
            nsort(min(size(W,2), 300)), nsort(min(size(W,2), 400)));
        fprintf(msg);
    end
    
    % increase iteration counter
    ii = ii+1;
end

fclose(fid); % close the data file if it has been used

rez.dWU      = gather_try(dWU);
rez.nspikes  = nspikes;

end
