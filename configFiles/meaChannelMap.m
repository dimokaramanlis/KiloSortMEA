

function channelmap = meaChannelMap(numelectrodes, electrodedist, savingpath, varargin)
%CREATE252CHANNELMAPFILE
%Doesn't reorder channels, the actual reordering is happening through convertMcdToRawBinaryCAR

if nargin>3
    excludeanalog = varargin{1};
else
    excludeanalog = true;
end


if numel(numelectrodes) ~= 2
    error('Weird electrode numbers!, number of electrode should be in two number format, like [16 16] or [8 8]');
end

xelecnum = numelectrodes(1);
yelecnum = numelectrodes(2);

[xcoords,ycoords]=meshgrid(0:1:xelecnum-1, yelecnum-1:-1:0);
if excludeanalog
    q = [1 1 size(xcoords,2) size(xcoords,2)];  % remove analog channels from the map
    p = [1 size(ycoords,1) 1 size(ycoords,1)];
    elecidx=sub2ind(size(xcoords),p,q);
    xcoords(elecidx)=[];
    ycoords(elecidx)=[];
end
xcoords=electrodedist*xcoords(:); 
ycoords=electrodedist*ycoords(:);

chanMap = 1:numel(xcoords); 
chanMap0ind = chanMap - 1;
connected = true(size(xcoords)); 
kcoords = ones(size(xcoords));

%-------------------------------------------------------------------------- 
if nargin > 2
    if not(exist(fullfile(savingpath, 'chanMap.mat'),'file'))
        save(fullfile(savingpath, 'chanMap.mat'), 'chanMap',...
            'chanMap0ind','connected', 'xcoords', 'ycoords', 'kcoords');
    else
        disp('we found channel map from previous run!');
    end
end

channelmap.chanMap = chanMap;
channelmap.chanMap0ind = chanMap0ind;
channelmap.connected = connected;
channelmap.xcoords = xcoords;
channelmap.ycoords = ycoords;
channelmap.kcoords = kcoords;
channelmap.numelectrodes = numelectrodes;
channelmap.electrodedist = electrodedist;

end