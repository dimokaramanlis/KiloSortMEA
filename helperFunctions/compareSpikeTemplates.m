function [simscore, lagim] = compareSpikeTemplates(spike_templates, varargin)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

% make maxLag be 1 ms (depends on sampling rate, should come in experiment)

if nargin<2
    verbose = true;
else
    verbose = varargin{1};
end

[Nt, Nyx, Nunits] = size(spike_templates);

maxLag = Nt-1;  %1 ms around peak!!!
lag = -maxLag:maxLag;

XCmat = zeros(Nunits, Nunits, length(lag), 'single');
spike_templates = permute(spike_templates, [2 1 3]);

if verbose
    tic;
    msg = sprintf('Calculating similarities: %d/%d lags, time elapsed: %2.2f s...\n', ...
        0, maxLag+1, toc); fprintf(msg);
end

for ilag = 0:maxLag
    %shift matrices

    Y1 = reshape(spike_templates(:, 1+ilag:end, :), Nyx * (Nt - ilag), Nunits); 
    Y2 = reshape(spike_templates(:, 1:end-ilag, :), Nyx * (Nt - ilag), Nunits);
    resmat = corr(Y1,Y2); %core calculation
    
    XCmat(:,:, maxLag+1+ilag) = resmat; 
    XCmat(:,:, maxLag+1-ilag) = resmat';
    %--------------------------------------------------------------------------
    if verbose
        fprintf(repmat('\b', 1, numel(msg)));
        msg = sprintf('Calculating similarities: %d/%d lags, time elapsed: %2.2f s...\n', ...
            ilag+1, maxLag+1, toc);
        fprintf(msg);
    end
    %--------------------------------------------------------------------------
end
if nargout < 2
    simscore = max(XCmat, [], 3);
else
    [simscore, im] = max(XCmat, [], 3);
    lagim = lag(im);
end

end