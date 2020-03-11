function [ftimes, fonsets, foffsets] = newframetimings(signal, ops)
%NEWFRAMETIMINGS Retrieve and save frame timings from the
% diode signal channel in a MC-Rack recording.
%
%	Input:		varargin			optional arguments in the form ('param',value)
%
%	Output:		
%               fonsets				frame signal onsets, in samples
%				foffsets            frame signal offsets, in samples
%==========================================================================
% parse inputs and check signal
madTh = ops.madThres;
fs = ops.fs; 
plotint = ops.plotint; plotinclude = ops.plotinclude; %in s
signal = signal(:);

T = length(signal)/fs;
fprintf('Total recording time: %ds\n', round(T));
%==========================================================================
% detect frame signals by threshold crossings
nsmooth = round(plotint*fs);
smooths = smoothdata(signal, 'gaussian', nsmooth);
Thres = madTh * mad(diff(smooths));

fonsets  = find( diff(diff(smooths) >  Thres) <0 ) + 1;
foffsets = find( diff(diff(smooths) < -Thres) >0 ) + 1;

% match onsets and offsets
if numel(foffsets)<numel(fonsets)
    fonsets = fonsets(1:end-1);
end
assert(numel(foffsets) == numel(fonsets))
%==========================================================================
% fix smoothing-induced shift
nsamps   = floor(plotint*fs);
shapeint = -nsamps:nsamps;

alfon  = signal(fonsets + shapeint);
aloff  = signal(foffsets + shapeint);

[~,ion]  = max(diff(alfon,[],2),[],2);
[~,ioff] = min(diff(aloff,[],2),[],2);

fonsets  = fonsets + shapeint(ion)' + 1;
foffsets = foffsets + shapeint(ioff)';
%==========================================================================
ftimes    = 0.5/fs + (fonsets-1)/fs; 
ftimesoff = 0.5/fs + (foffsets-1)/fs; 
if isempty(fonsets)
	warning('No frame signal found, exiting...');
	fonsets = []; foffsets = []; ftimes = [];  ftimesoff = [];% dummy values
end
%==========================================================================
% plots 
if ops.Show && ~isempty(fonsets)
    nplot = floor(plotinclude*fs);
    
    fonplot = fonsets(fonsets < fonsets(1)+nplot);
    foffplot = foffsets(foffsets < fonsets(1)+nplot);

    tplot = (fonsets(1)+(0:nplot-1))/fs + 0.5/fs;
    signalplot = signal(fonsets(1)+(0:nplot-1));
    ypulses = min(signalplot)+range(signalplot)/2;

    tshape = shapeint*1e3/fs;
    alignedpulseson =  signal(fonplot+shapeint);
    alignedpulsesoff = signal(foffplot+shapeint);

    ymax = max([alignedpulseson(:);alignedpulsesoff(:)]);

    mf = figure('Position', [100 100 1600 850],'color','w','Visible','off');    
    subplot(2,2, 1)
    line(tshape, alignedpulseson', 'LineStyle','-','Color',[0 0.45 1 0.6]);
    xlabel('Time from pulse onset (ms)'); xlim(plotint * 1e3* [-1 1]);
    ylabel('Voltage (V)'); ylim([0 ymax+0.025]);
    ax = gca; ax.Box = 'off';       ax.TickDir = 'out';     pbaspect([2 1 1]);
    xticks(-10:0.1:10);        yticks(round(double([0 ymax/2 ymax]),1));      title('onset');

    subplot(2,2, 2)
    line(tshape, alignedpulsesoff', 'LineStyle','-','Color',[0 0.45 1 0.6]);
    xlabel('Time from pulse offset (ms)'); xlim(plotint * 1e3* [-1 1]);
    ylabel('Voltage (V)'); ylim([0 ymax+0.025]);
    ax = gca; ax.Box = 'off';       ax.TickDir = 'out';     pbaspect([2 1 1]);
    xticks(-10:0.1:10);        yticks(round(double([0 ymax/2 ymax]),1));      title('offset');
    
    subplot(2,2, [3 4])
    tonsets = (fonplot-1)/fs; toffsets = (foffplot-1)/fs;
    ax = gca; ax.Box = 'off';       ax.TickDir = 'out';
    xlabel('Time (s)'); xlim([tplot(1) tplot(end)]);
    ylabel('Voltage (V)'); ylim([0 ymax+0.025]);
    line(tplot, signalplot,'LineStyle','-', 'Color', [0 0.4 1 0.6],'Marker','none');
    line(toffsets, ypulses, 'LineStyle','none', 'Color', 'm','Marker','o');
    line(tonsets, ypulses, 'LineStyle','none', 'Color', 'r','Marker','x');
    title('onsets: x, offsets: o');
    pbaspect([5 1 1]);
    yticks(round(double([0 ymax/2 ymax]),1));

    %savepngFast(mf, ops.exportpath,[ops.filename '_frametimings'], 400);
    set(mf,'PaperPositionMode','auto')
    print(fullfile(ops.exportpath,[ops.filename '_frametimings.png']), '-dpng','-r0');
    close(mf);
end
%==========================================================================
% save to disk
if ops.Save
    psave = fullfile(ops.exportpath, [ops.filename '_frametimings.mat']);
    save(psave,'ftimes', 'ftimesoff', 'foffsets', 'fonsets','fs', '-v7.3');
end
%==========================================================================
end