function [targetfolder, namestoread] = recordingPaths(pairstr)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
mainpath   = 'S:\ElboustaniLab\#SHARE\Data\0Dyad_JointPerceptualDecisionMaking';
recordpath = fullfile(mainpath,pairstr,'Recordings/Neuropixels/');
targetbinpath = 'E:\';

recordtypes = dir(recordpath);
iuse        = cellfun(@(x) ~contains(x, '.'),{recordtypes(:).name});
recordtypes = recordtypes(iuse);

bigcellcontainer = cell(numel(recordtypes), 1);

for itype = 1:numel(recordtypes)
    alldates    = dir(fullfile(recordtypes(itype).folder, recordtypes(itype).name, '20*'));
    allpaths    = cell(numel(alldates), 5, 2);
    for idate = 1:numel(alldates)
        allsessions = dir(fullfile(alldates(idate).folder, alldates(idate).name,'Session*'));
        for isess = 1:numel(allsessions)
            for imouse = 0:1
                pathbin = dir(fullfile(allsessions(isess).folder, allsessions(isess).name, sprintf('*imec%d',imouse)));
                npfile  = dir(fullfile(pathbin.folder, pathbin.name,'*ap.bin'));
                allpaths{idate, isess, imouse+1} = fullfile(npfile.folder, npfile.name);
            end
        end

    end
    bigcellcontainer{itype} = allpaths;
end

bigcellcontainer = cat(1,bigcellcontainer{:});
bigcellcontainer = bigcellcontainer(:);
irem = cellfun(@isempty, bigcellcontainer);
bigcellcontainer(irem) = [];


% extract date 


% extract date 
regresult   = regexp(bigcellcontainer(:),'\d{8}','match');
if any(cellfun(@isempty,regresult))
    iempty = cellfun(@isempty,regresult);
    iother = mod(icoluse, numel(modalityidentifiers)) + 1;
    regresult(iempty) = regexp(sesslist(iempty,iother),'\d{8}','match');
end
listdates = cellfun(@(x) str2double(x{1}), regresult, 'un',0);

[datesun, ~, id]= unique(cat(1,listdates{:}));
pathsmouse = cell(numel(datesun), 2);
for ii = 1:numel(datesun)
    candpaths = bigcellcontainer(id == ii);
    for imouse = 0:1
        pathsmouse{ii, imouse+1} = candpaths(contains(candpaths, sprintf('imec%d',imouse)));
    end

end

namestoread = pathsmouse(:);
for icomb = 1:numel(namestoread)
    alldates = NaN(numel(namestoread{icomb}), 1);
    for ifile = 1:numel(namestoread{icomb})
        fileinfo = dir(namestoread{icomb}{ifile});
        alldates(ifile) = fileinfo.datenum;
    end
    [~, isort] = sort(alldates,'ascend');
    namestoread{icomb} = namestoread{icomb}(isort);
end

targetfolder = cell(numel(namestoread), 1);
for icomb = 1:numel(namestoread)
    if all(contains(namestoread{icomb}, 'imec0'))
        mousename = pairstr(1:5);
    else
        mousename = pairstr(7:end);
    end
    regresult   = regexp(namestoread{icomb},'\d{8}','match');
    targetfolder{icomb} = fullfile(targetbinpath, sprintf('%s_%s',regresult{1}{1},mousename));
    if ~exist(targetfolder{icomb},'dir')
        mkdir(targetfolder{icomb})
    end
end


end