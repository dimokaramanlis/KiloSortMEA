function [data, scanrate, all_return_vars, status] = load_multichannel_systems_mcd(full_filename, region_to_load)
% Loads a multichannel systems 'mcd' file.

    %% for reference, see 'Neuroshare.m'

    %% if no region_to_load is given, set default.
    if nargin < 2
        region_to_load = [1 10000]; % sample numbers in file to return.
    end
    
    %% get location of this file & load 'nsMCDLibraryPLATFORM.EXT' which 
    % is expected to be in the same folder.
    
    file_location = which('load_multichannel_systems_mcd');
    path_to_file = fileparts(file_location);
    
    switch computer()
        case 'PCWIN'
            lib_to_load = 'nsMCDLibraryWin32.dll';
        case 'GLNX86'
            lib_to_load = 'nsMCDLibraryLinux32.so';
        case 'PCWIN64'
            lib_to_load = 'nsMCDLibraryWin64.dll';
        case 'GLNXA64'
            lib_to_load = 'nsMCDLibraryLinux64.so';
        case 'MACI64'
            lib_to_load = 'nsMCDLibraryMacIntel.dylib';
        otherwise
            disp('Your architecture is not supported');
            status = 1;
            data = [];
            scanrate = [];
            all_return_vars = [];
            return;
    end
    
    % setup library
    nsresult = ns_SetLibrary([path_to_file filesep lib_to_load]); %#ok<NASGU>
    %[nsresult, info] = ns_GetLibraryInfo();
    
    %% get file info
    
    % get file handle
    [nsresult, hfile] = ns_OpenFile(full_filename); %#ok<ASGLU>
    
    % read out file info
    [nsresult, FileInfo] = ns_GetFileInfo(hfile); %#ok<ASGLU>
    
    scanrate = round(1 / FileInfo.TimeStampResolution);
    
    %% Build catalogue of entities
    
    % Multichannel codes the digital channel (16 bit) as an
    % analog entity with EntityType = 2. Therefore we also have to
    % check for information in Entity Label.
    
    [nsresult, EntityInfo] = ns_GetEntityInfo(hfile, 1 : FileInfo.EntityCount); %#ok<ASGLU>
    allEntityInfo = [EntityInfo.EntityType];
    
    % List of EntityIDs needed to retrieve the information and data.
    % The EntityIDs are take from here:
    % http://neuroshare.sourceforge.net/Matlab-Import-Filter/NeuroshareMatlabAPI-2-2.htm#_Toc61163407
    %
    % Unknown entity                   0
    % Event entity                     1
    % Analog entity                    2 % Problem: also the digital data has entityID 2
    % Segment entity                   3
    % Neural event entity              4
    %
    
    %     EventList = find(allEntityInfo == 1); % see below.
    %     AnalogList = find(allEntityInfo == 2); % see below.
    SegmentList = find(allEntityInfo == 3); % unsure what this is
    NeuralList = find(allEntityInfo == 4); % unsure what this is
    
    LabelList = {EntityInfo.EntityLabel}; % extract labels of the entities. Something like 'digi0001 0063 0000       D1' or 'elec0001 0016 0000       17'
    AnalogList = get_channel_name_from_string(LabelList, 'elec');
    EventList = get_channel_name_from_string(LabelList, 'digi');
    
    % If you recorded triggers with the MC software you can read them out
    % with the following lines:
    % TriggerIndex = strfind(LabelList, 'trig'); % find which entities say 'trig' in their label, indicating a trigger channel.
    % TriggerIndex = find(cellfun(@(x) ~isempty(x), TriggerIndex));
    
    % How many of a particular entity do we have
    nbr_Neural = length(NeuralList);
    nbr_Segment = length(SegmentList);
    nbr_Analog = length(AnalogList);
    nbr_Event = length(EventList);
    
    %% manually sub-select analog channels
    % TODO: make this an input option to this function.
    AnalogList = [ 18 21 ];
    nbr_Analog = length(AnalogList);
    
    %% let's start by reading out the analog channels first.

    nbr_channels = nbr_Analog;
    max_range = region_to_load(2);
    min_range = region_to_load(1);
    nbr_samples = diff(region_to_load) + 1;
    data = nan(nbr_channels, nbr_samples);
    ChannelNames = cell(1, nbr_channels);
    
    %
    nbr_samples_each_channel = zeros(1, nbr_channels);
    for j = 1 : numel(AnalogList)
        
        chan = AnalogList(j);
        ChannelNames{j} = ['Analog Ch# ' num2str(EntityInfo(chan).EntityLabel(end-1:end))]; %'elec0001 0016 0000       17'
        
        % we can not access more than 'EntityInfo(chan).ItemCount' samples
        % of the current channel.
        nbr_samples_each_channel(j) = min(max_range-min_range+1, EntityInfo(chan).ItemCount);
        
        % Get the fist data points of the waveform and show it
        [nsresult, ContinuousCount, data_tmp] = ns_GetAnalogData(hfile, AnalogList(j), min_range, nbr_samples_each_channel(j)); %#ok<ASGLU>
        data(j, 1:nbr_samples_each_channel(j)) = data_tmp;
        %     [nsresult,analog] = ns_GetAnalogInfo(hfile,chan) %
        %     getAnalogInfo returns a structure with
        
    end

    % remove extra data points
    data(:, min(nbr_samples_each_channel) + 1 : end) = [];
    
    %% read-in event data & write events to extra channel
    
    chan = EventList(1); % It seems only the first 'digi' channel contains data.
    nbr_samples_events = min(max_range-min_range+1, EntityInfo(chan).ItemCount);
    
    [nsresult, ContinuousCount, data_tmp] = ns_GetAnalogData(hfile, chan, min_range, nbr_samples_events); %#ok<ASGLU>
    data(end + 1, 1:nbr_samples_events) = data_tmp;
    
    % add event channel name to list of channels & the number of channels.
    ChannelNames{end + 1} = 'Events';
    nbr_channels = nbr_channels + 1;
    
    %%
    max_nbr_samples_in_file = min([EntityInfo(AnalogList).ItemCount]);
    FileRegionLoaded = region_to_load;
    
    % this is a fake value!
    dynamic_range = 5;
    
    %% clean up
    
    % Close data file. Should be done by the library but just in case.
    ns_CloseFile(hfile);
    
    % Unload DLL
    clear mexprog;
    
    %%
    status = 0;
    all_return_vars = load_pack_remaining(max_nbr_samples_in_file, nbr_channels, FileRegionLoaded, dynamic_range, ChannelNames);

end

function all_return_vars = load_pack_remaining(max_nbr_samples_in_file, nbr_channels, FileRegionLoaded, dynamic_range, ChannelNames) %#ok<INUSD>
% see load_files_pack_wrapper.m - this is basically a copy of it
% !! DO NOT CHANGE THE NAMES OF THE INPUT VARIABLES!!
%
%
% packs all additional variables into a structure.
% use 'unpack_variables' to get them back.
    
    % count how many variables we have and put them all into one
    % 'parameters' structure
    all_variables = whos;
    all_return_vars = pack_variables(all_variables);

end

function channellist = get_channel_name_from_string(LabelList, string)

    channellist = strfind(LabelList, string); % find which entities say 'elec' in their label, indicating an analog channel.
    channellist = find(cellfun(@(x) ~isempty(x), channellist));
    
end

%% EOF
