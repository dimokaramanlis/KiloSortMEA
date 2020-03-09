function create252ChannelMapFile(fpath)
%CREATE252CHANNELMAPFILE
%Doesn't reorder channels, the actual reordering is happening through convertMcdToRawBinaryCAR
%--------------------------------------------------------------------------
xmax=16; ymax=16; elDist=100;
[xcoords,ycoords]=meshgrid(0:1:xmax-1, ymax-1:-1:0);
q = [1 1 xmax xmax]; p = [1 xmax 1 xmax];
idx=sub2ind(size(xcoords),q,p);
xcoords(idx)=[]; ycoords(idx)=[];
xcoords=elDist*xcoords(:); ycoords=elDist*ycoords(:);

chanMap=1:numel(xcoords); chanMap0ind = chanMap - 1;
connected=true(size(xcoords)); kcoords=ones(size(xcoords));
fs=10000;
%-------------------------------------------------------------------------- 
save(fullfile(fpath, 'chanMap.mat'), 'chanMap',...
    'chanMap0ind','connected', 'xcoords', 'ycoords', 'kcoords','fs')
end