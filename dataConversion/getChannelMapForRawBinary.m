
function [chanMap, analogChs] = getChannelMapForRawBinary(labellist, varargin)

p = inputParser();
p.addParameter('dataformat', 'mcd', @(x) ischar(x));
p.addParameter('channelnumber', 256, @(x) isnumeric(x));    % default value is for 256
p.addParameter('meatype', '252MEA10030', @(x) ischar(x));    % default value is for 256
p.parse(varargin{:});
para = p.Results;

switch lower(para.dataformat)
    case {'mcd','mcrack','old','mc'}
        
        [chanMap, analogChs] = getMCDchannelMap(labellist, para);
        
    case {'msrd','mcsd','new','h5','hdf5'}
        
        chanMap = getMSRDchannelMap(labellist, para);
        
    otherwise
        error(['There aint no data format ',para.dataformat,' here, come back when you have proper data!']);
end

end


function [chanMap, analogChs, sortedtext] = getMCDchannelMap(labellist, para)

%anlg=contains(labellist,'anlg0001');
%chnames = regexprep(extractAfter(labellist,'      '), '\s+', '')';
anlg=contains(labellist,'anlg0001');
chnames = regexprep(extractAfter(labellist,'      '), '\s+', '')';
%meachnum = para.channelnumber;%size(labellist,2);

if para.channelnumber == 256 % 252 MEA
    R = cell2mat(regexp(chnames,'(?<Name>\D+)(?<Nums>\d+)','names'));
    namesCell=[{R.Name}' {R.Nums}'];
    %remove analog channels already before sorting (don't have to be sorted)
    namesCell(anlg,:)=[{'A'} {'1'}; {'A'} {'16'};{'R'} {'1'};{'R'} {'16'}];
    [~,chmeaidx] = sortrows([namesCell(:,1) num2cell(cellfun(@(x)str2double(x),namesCell(:,2)))]);
    chanMap=chmeaidx(~anlg(chmeaidx))-1;
    analogChs = chmeaidx(anlg(chmeaidx))-1;
    
elseif para.channelnumber == 63 % 60 MEA, other types like HD-MEA, perforated MEA need to be added
    
    if any(strcmpi(para.meatype,{'60pMEA10030','60pMEA20030'})) % this is only for perforated MEA
        [sortedtext,chmeaidx] = sortrows(chnames);
        chanMap=chmeaidx(~anlg(chmeaidx))-1;
        analogChs = chmeaidx(anlg(chmeaidx))-1;
    else
        [sortedtext,chmeaidx] = sortrows(chnames(1:end-3));
        chmeaidx = [61;chmeaidx];       sortedtext = ['61';sortedtext];   % add channel 61 to position 1
        chmeaidx = [chmeaidx(1:7);62;chmeaidx(8:end)];      % add channel 62 to position 8
        sortedtext = [sortedtext(1:7);'62';sortedtext(8:end)];
        chmeaidx = [chmeaidx(1:56);63;chmeaidx(57:end)];    % add channel 63 to position 57
        sortedtext = [sortedtext(1:56);'63';sortedtext(57:end)];
        chanMap=chmeaidx(~anlg(chmeaidx))-1;
        analogChs = chmeaidx(anlg(chmeaidx))-1;
    end
    
elseif para.channelnumber == 64 % 60 MEA, other types like HD-MEA, perforated MEA need to be added
    [sortedtext,chmeaidx] = sortrows(chnames(1:end-3));
    chmeaidx = [61;chmeaidx];       sortedtext = ['61';sortedtext];   % add channel 61 to position 1
    chmeaidx = [chmeaidx(1:7);62;chmeaidx(8:end)];      % add channel 62 to position 8
    sortedtext = [sortedtext(1:7);'62';sortedtext(8:end)];
    chmeaidx = [chmeaidx(1:56);63;chmeaidx(57:end)];    % add channel 63 to position 57
    sortedtext = [sortedtext(1:56);'63';sortedtext(57:end)];
    chmeaidx = [chmeaidx;64];
    sortedtext = [sortedtext;'64'];   % add channel 64 to position 64
    chanMap=chmeaidx(~anlg(chmeaidx))-1;
    analogChs = chmeaidx(anlg(chmeaidx))-1;
end
end


function [chanMap, chanIDs] = getMSRDchannelMap(labellist, para)

if para.channelnumber == 60
    %chnums = 1:para.channelnumber;
    if diff(size(labellist))==0
        labellist = labellist{1};
    end
    labellist {contains(labellist,'Ref')} = '15';
    chanMap = str2double(labellist);
    [chanIDs, chmeaidx] = sort(chanMap,'ascend'); % this is convert channel XY location to index
    chanMap = chmeaidx-1;
    
elseif para.channelnumber == 252
    chnames = labellist{1};
    R = cell2mat(regexp(chnames,'(?<Name>\D+)(?<Nums>\d+)','names'));
    namesCell=[{R.Name}' {R.Nums}'];
    [~,chmeaidx] = sortrows([namesCell(:,1) num2cell(cellfun(@(x)str2double(x),namesCell(:,2)))]);
    chanMap = chmeaidx-1;
end
end
