function chanMap = getChannelMapForRawBinary(labellist)

anlg=contains(labellist,'anlg0001');
chnames = regexprep(extractAfter(labellist,'      '), '\s+', '')';
anlg=contains(labellist,'anlg0001');
chnames = regexprep(extractAfter(labellist,'      '), '\s+', '')';
meatype = size(labellist);
if meatype(2) == 256 % 252 MEA
    R = cell2mat(regexp(chnames,'(?<Name>\D+)(?<Nums>\d+)','names'));
    namesCell=[{R.Name}' {R.Nums}'];
    %remove analog channels already before sorting (don't have to be sorted)
    namesCell(anlg,:)=[{'A'} {'1'}; {'A'} {'16'};{'R'} {'1'};{'R'} {'16'}];
    [~,chmeaidx] = sortrows([namesCell(:,1) num2cell(cellfun(@(x)str2double(x),namesCell(:,2)))]);
    chanMap=chmeaidx(~anlg(chmeaidx))-1;
elseif meatype(2) == 63 % 60 MEA, other types like HD-MEA, perforated MEA need to be added
    [sortedtext,chmeaidx] = sortrows(chnames(1:end-3));
    chmeaidx = [61;chmeaidx];       sortedtext = ['61';sortedtext];   % add channel 61 to position 1
    chmeaidx = [chmeaidx(1:7);62;chmeaidx(8:end)];      % add channel 62 to position 8
    sortedtext = [sortedtext(1:7);'62';sortedtext(8:end)];
    chmeaidx = [chmeaidx(1:56);63;chmeaidx(57:end)];    % add channel 63 to position 57
    sortedtext = [sortedtext(1:56);'63';sortedtext(57:end)];
%    chmeaidx = [chmeaidx;64];       sortedtext = [sortedtext;'64'];   % add channel 64 to position 64
    chanMap=chmeaidx(~anlg(chmeaidx))-1;
end
end