

function channelmap = hexaChannelMap(savingpath)
%CREATE252CHANNELMAPFILE
%Doesn't reorder channels, the actual reordering is happening through convertMcdToRawBinaryCAR


elecdist = 40;


[x1, y1] = meshgrid(1.5:1:5.5, 0:sqrt(3):sqrt(3)*4);
[x2, y2] = meshgrid(1:6, (sqrt(3)/2):sqrt(3):(sqrt(3)*7/2));
x3 = [0  0 0.5 0.5 0.5 6.5 6.5 6.5 7 7];
y3 = [3/2 5/2 1 2 3 1 2 3 3/2 5/2] * sqrt(3);

xall = [x1(:);x2(:); x3(:)] * elecdist;
yall = [y1(:);y2(:); y3(:)] * elecdist;

chcoords = sortrows([xall, yall], [1 -2]);

xcoords = [chcoords(:,1); 0];
ycoords = [chcoords(:,2); 0];

chanMap = 1:numel(xcoords); 
chanMap0ind = chanMap - 1;
connected = true(size(xcoords)); 
connected(end) = false; % disconnect ground
kcoords = ones(size(xcoords));

%-------------------------------------------------------------------------- 
save(fullfile(savingpath, 'chanMap.mat'), 'chanMap',...
    'chanMap0ind','connected', 'xcoords', 'ycoords', 'kcoords');
%--------------------------------------------------------------------------
channelmap.chanMap = chanMap;
channelmap.chanMap0ind = chanMap0ind;
channelmap.connected = connected;
channelmap.xcoords = xcoords;
channelmap.ycoords = ycoords;
channelmap.kcoords = kcoords;
channelmap.numelectrodes = 60;
channelmap.electrodedist = elecdist;

end