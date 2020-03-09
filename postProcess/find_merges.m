function rez = find_merges(rez, flag)
% this function merges clusters based on template correlation
% however, a merge is veto-ed if refractory period violations are introduced

ops = rez.ops;
dt = 1/1000;

Xsim = rez.simScore; % this is the pairwise similarity score
Nk = size(Xsim,1);
Xsim = Xsim - diag(diag(Xsim)); % remove the diagonal of ones

st = rez.st3;

[~, iclust] = sort(st(:,2),'ascend');
st = st(iclust, :);
rez.st3(:,5) = rez.st3(:,2);
% sort by firing rate first
nspk = accumarray(st(:,2), 1, [Nk, 1], @sum);
[~, isort] = sort(nspk); % we traverse the set of neurons in ascending order of firing rates
fprintf('initialized spike counts\n')

if ~flag
  % if the flag is off, then no merges are performed
  % this function is then just used to compute cross- and auto- correlograms
   rez.R_CCG = Inf * ones(Nk);
   rez.Q_CCG = Inf * ones(Nk);
   rez.K_CCG = {};
end

spktoind = [0;cumsum(nspk)];

tracksort = zeros(Nk, 30, 'single');
for j = 1:Nk
    
    if nspk(isort(j)) < 100; continue; end;
    
    Nmerged1 = nnz(tracksort(isort(j),:));
    s1 = st(spktoind(isort(j))+1:spktoind(isort(j)+1),1)/ops.fs;

    for im = 1:Nmerged1
        cind = tracksort(isort(j), im);
        snew = st(spktoind(cind)+1:spktoind(cind+1),1)/ops.fs;
        s1   = cat(1, s1, snew);
    end
    
    if numel(s1)~=nspk(isort(j))
        fprintf('lost track of spike counts') %this is a check for myself to make sure new cluster are combined correctly into bigger clusters
    end
    % sort all the pairs of this neuron, discarding any that have fewer spikes
    [ccsort, ix] = sort(Xsim(isort(j),:) .* (nspk'>numel(s1)), 'descend');
    ienu = find(ccsort<.5, 1) - 1; % find the first pair which has too low of a correlation

    % for all pairs above 0.5 correlation
    for k = 1:ienu

        Nmerged2 = nnz(tracksort(ix(k),:));
        s2 = st(spktoind(ix(k))+1:spktoind(ix(k)+1),1)/ops.fs;

        for im = 1:Nmerged2
            cind = tracksort(ix(k), im);
            snew = st(spktoind(cind)+1:spktoind(cind+1),1)/ops.fs;
            s2   = cat(1, s2, snew);
        end
        
        % compute cross-correlograms, refractoriness scores (Qi and rir), and normalization for these scores
        [K, Qi, Q00, Q01, rir] = ccg(s1, s2, 500, dt);
        Q = min(Qi/(max(Q00, Q01))); % normalize the central cross-correlogram bin by its shoulders OR by its mean firing rate
        R = min(rir); % R is the estimated probability that any of the center bins are refractory, and kicks in when there are very few spikes
        if flag 
            if Q<.2 && R<.05 % if both refractory criteria are met
            i = ix(k);
            % now merge j into i and move on
            rez.st3(rez.st3(:,5)==isort(j),5) = i; % simply overwrite all the spikes of neuron j with i (i>j by construction)
            nspk(i) = nspk(i) + nspk(isort(j)); % update number of spikes for cluster i
            tracksort(i, Nmerged2+(1:(Nmerged1+1))) = [isort(j) tracksort(isort(j),1:Nmerged1)];
            tracksort(isort(j), :) = 0;
            fprintf('merged %d into %d \n', isort(j), i)
            % YOU REALLY SHOULD MAKE SURE THE PC CHANNELS MATCH HERE
            break; % if a pair is found, we don't need to keep going (we'll revisit this cluster when we get to the merged cluster)
            end
        else
            % sometimes we just want to get the refractory scores and CCG
            rez.R_CCG(isort(j), ix(k)) = R;
            rez.Q_CCG(isort(j), ix(k)) = Q;

            rez.K_CCG{isort(j), ix(k)} = K;
            rez.K_CCG{ix(k), isort(j)} = K(end:-1:1); % the CCG is "antisymmetrical"
        end
        
    end
    
end
%--------------------------------------------------------------------------
if ~flag
    rez.R_CCG  = min(rez.R_CCG , rez.R_CCG'); % symmetrize the scores
    rez.Q_CCG  = min(rez.Q_CCG , rez.Q_CCG');
end
%--------------------------------------------------------------------------
end
