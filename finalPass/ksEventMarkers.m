

function [stimtimes , mcnames] = ksEventMarkers(bininfopath, mcpath, varargin)
%
%%% ksEventMarkers %%%
%
%
% This function writes eventmarkers.txt and eventmarkernames.txt to the
% ks_sorted folder. These files are then used by the eventmarker plugin of
% the phy to show the stimulus events in the amplitude view.
%
%
% ===============================Inputs====================================
%
%   bininfopath : folder path to the bininfo file, generally ks_sorted folder.
%   mcpath : path to the raw data folder to get the file names. if not
%            provided the eventmarkernames.txt is not generated.
%   for optional input check the input parser below.
%
%================================Output====================================
%
%   no output : this is a plotting function and no output is produced.
%
% written by Mohammad, 03.03.2020.

if nargin < 2
    mcpath = fileparts(bininfopath);
end

% options
p = inputParser();
p.addParameter('writemarkernames', true, @(x) islogical(x)); % flag to write the file names
% flag to write the output numbers in seconds instead of samples (no difference in the final presentation in phy)
p.addParameter('inseconds', false, @(x) islogical(x));
p.addParameter('shortformat', false, @(x) islogical(x)); % flag to shorten the names of files to 30 characters
p.addParameter('shortformatlength', 30, @(x) isnumeric(x)); % length of shortened characters.
% parse inputs
p.parse(varargin{:});
ops = p.Results;

bininfo = struct2array(load([bininfopath,'/bininfo.mat']));

% try mcd first, if not try h5
mcnames = dir([mcpath,filesep,'*.mcd']);
formname = '.mcd';

if isempty(mcnames)
    mcnames = dir([mcpath,filesep,'*.h5']);
    formname = '.h5';
end

if isempty(mcnames)
    warning('Hey, Yo, Aint nobody got the file names here, your mcpath is bullshit');
    ops.writemarkernames = false;
end


stimtimes = [0;cumsum(bininfo.stimsamples(1:end-1))];
if ops.inseconds
    stimtimes = stimtimes./bininfo.fs ;
    numform = '%f\r\n';
else
    numform = '%d\r\n';
end

fidOut= fopen([bininfopath,filesep,'eventmarkers.txt'], 'W');
fprintf(fidOut,numform,stimtimes);
fclose(fidOut);


% write text files
if ops.writemarkernames
    [stimind, reindex]=sort(str2double(regexp(({mcnames(:).name}),'\d+','match','once')));

    namesuse = logical([1 diff(stimind)]);
    fnames   = {mcnames(reindex).name}';
    fnames   = fnames(namesuse);
    fnames  = extractBefore(fnames,formname);
    
    fidOut = fopen([bininfopath,filesep, 'eventmarkernames.txt'], 'W');
    for ii = 1: size(fnames,1)
        if ops.shortformat
            nlen = length(fnames{ii});
            if nlen > ops.shortformatlength
                fprintf(fidOut,'%s\r\n',fnames{ii}(1:ops.shortformatlength));
            else
                fprintf(fidOut,'%s\r\n',fnames{ii});
            end
        else
            fprintf(fidOut,'%s\r\n',fnames{ii});
        end
    end
    fclose(fidOut);
end

end