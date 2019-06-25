function [data, scanrate, all_return_vars, status] = load_multichannel_systems_raw(full_filename, region_to_load)
% load a multichannel systems 'raw' file with 'load_MCS_raw' and return
% data in 'FileBrowser' compatible format.

    %% if no region_to_load is given, set default.
    if nargin < 2
        region_to_load = [1 10000];
    end

    %% load the file & scanrate
    [datatmp, metadata] = load_MCS_raw(full_filename, [], region_to_load);
    
    % extract scanrate from metadata
    scanrate = metadata.SampleRate;

    nbr_channels = numel(datatmp);
    % convert cell into matrix
    if iscell(datatmp)
        nbr_samples = unique(cellfun(@(x) numel(x), datatmp));
        data = zeros(nbr_channels, nbr_samples);
        for j = 1 : nbr_channels
            data(j, :) = datatmp{j}';
        end
    else
        data = datatmp;
    end
    %%
    max_nbr_samples_in_file = metadata.max_nbr_samples_in_file;
    FileRegionLoaded = region_to_load;
    ChannelNames = metadata.ChannelNames;
    if isempty(ChannelNames)
        ChannelNames = arrayfun(@(x) num2str(x), 1:nbr_channels, 'UniformOutput', 0);
    end
    dynamic_range = 5;
     
    %%
    status = 0;
    all_return_vars = load_pack_remaining(max_nbr_samples_in_file, nbr_channels, FileRegionLoaded, dynamic_range, ChannelNames);

end

function all_return_vars = load_pack_remaining(max_nbr_samples_in_file, nbr_channels, FileRegionLoaded, dynamic_range, ChannelNames)
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
%% EOF
