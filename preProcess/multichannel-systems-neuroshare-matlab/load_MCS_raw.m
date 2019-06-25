function [rawData, metadata] = load_MCS_raw(path, channels_to_load, time)
% Use to load 'raw' files that have been converted from 'mcs' files. 
% load_MCS_raw(path, channels_to_load, time) "path" is a string giving the path and
% file name of the .raw electrophysiology data file. "channels_to_load" are the
% channels which should be extracted. For analog data channel 3 this would
% be {'E03'}, for digital channel 2 {'D2'}. Time is a 2 element vector
% containing the beginning and end of a ROI to load (time in sample number).
% Function extracts data from raw electrophysiology files exported by the
% Multichannel software. Accesses data in memory-compatible junks directly
% from hard drive.
% 
% TO-DO:
%   - Check how the MCS system defines the analog channels in the header.
%     Then recode accordingly
%   - doesn't do conversion of electrode channels 
%
% Based heavily on Ingmar Schneider's ImportMCS function, adapted with the
% help of Andreas Kotowicz to the present form.
% lorenzpammer 12/2011

%% check inputs 

if nargin < 3
   time = []; 
end
% if nargin < 2
%     channels_to_load = {'D1' 'E01'    'E02'    'E03'    'E04'    'E05'    'E06'    'E07'    'E08'    'E09'    'E10'    'E11'    'E12'    'E13'    'E14',...
%          'E15'    'E16'    'E17'    'E18'    'E19'    'E20'    'E21'    'E22'    'E23'    'E24'    'E25'    'E26'    'E27'    'E28',...
%         'E29'    'E30'    'E31'    'E32'};
% end

    %% Select and open raw file
    
    fid = fopen(path, 'r', 'ieee-le.l64');
    
    
    %% Read all hdr fields and convert to an array
    dataHdr = [];
    HdrTemp = textscan(fid, '%s', 8, 'delimiter', '\b'); % Read the topmost 8 lines of text
    position = ftell(fid);
    disp(['position after header: ' num2str(position)]);
    
    FileNameMCS = textscan(HdrTemp{1,1}{3,1}, '%s', 'delimiter', sprintf('\"'));
    FileNameTemp = regexp(FileNameMCS{1,1}{2,1}, '\\', 'split');
    dataHdr.FileName = strcat(FileNameTemp{1,end}(1:(end-4)),'.raw'); 
        
    dataHdr.Import.MC_DataToolVersion = HdrTemp{1,1}{2,1};
    
    SampleRateTemp = textscan(HdrTemp{1,1}{4,1}, '%s');
    dataHdr.SampleRate = str2double(SampleRateTemp{1,1}{4,1});
    
    ADCTemp = textscan(HdrTemp{1,1}{5,1}, '%s');
    dataHdr.Import.ADC_Zero = str2double(ADCTemp{1,1}{4,1});
    
    ADStepTemp = textscan(HdrTemp{1,1}{6,1}, '%s', 'delimiter', ';');
    
    % Alternative determination of ADStep for electrode and analog-Channels
    for s = 1:size(ADStepTemp{1,1})
        if strncmp('An', ADStepTemp{1,1}{s,1}, 2) == 1;
            dataHdr.Import.An_ADStep = str2double(ADStepTemp{1,1}{s,1}(6:11));
        elseif strncmp('El', ADStepTemp{1,1}{s,1}, 2) == 1;
            dataHdr.Import.El_ADStep = str2double(ADStepTemp{1,1}{s,1}(6:11));
        elseif strncmp('Di', ADStepTemp{1,1}{s,1}, 2) == 1;
            % No AD-conversion for digital inputs!
        end;
    end;
    
    ChannelTemp = textscan(HdrTemp{1,1}{7,1},  '%s', 'delimiter', ';');
    ChannelTemp{1,1}{1,1} = ChannelTemp{1,1}{1,1}(11:end);  % Cut away the trailing 'Streams = '
    dataHdr.Channels = ChannelTemp{1,1};
    
    dataHdr.Import.DimOrd = 'ChannelxTime';
    nbr_channels = numel(dataHdr.Channels);
    
    %% extract absolute channel numbers
    
    % if no channel names were given, load all channels.
    if nargin < 2
        channel_number_to_load = 5;
        % channel_number_to_load = [1 5 7];
        % dirty hack - we need to reconstruct the channel names from the
        % numbers again (we need this for the scaling in lines ~ 162)
        channels_to_load = {};

    % no channel names were given, but 'time' was given - construct channel
    % names from the info that we've got, so that the channels get
    % normalized accordingly.
    elseif nargin == 3 && isempty(channels_to_load)
        channel_number_to_load = 1:nbr_channels;
        channels_to_load = cell(1, nbr_channels);
        digital_channels = get_channel_name_from_string(dataHdr.Channels, 'Di');
        electrode_list = get_channel_name_from_string(dataHdr.Channels, 'E');
        
        % create 'channels_to_load' in the following format:
        % channels_to_load = {'D1' 'E01'    'E02'    'E03'    'E04'   }
        for j = 1 : numel(digital_channels)
            full_name = dataHdr.Channels{digital_channels(j)};
            channels_to_load{digital_channels(j)} = ['D' num2str(full_name(end))];
        end
        
        for j = 1 : numel(electrode_list)
            full_name = dataHdr.Channels{electrode_list(j)};
            channels_to_load{electrode_list(j)} = ['E' num2str(full_name(end-1:end))];
        end
        
    % remap channel names to absolute channel numbers
    else
        
        nbr_channels_to_load = numel(channels_to_load);
        channel_number_to_load = zeros(1, nbr_channels_to_load);
        
        for i = 1 : nbr_channels_to_load
            
            channelToRead = channels_to_load{i};
            channelType = channelToRead(1);
            
            switch channelType
                case 'D'% digital channel
                    channelToRead = str2double(channelToRead(2));
                    disp('Di')
                    if isempty(strncmp(dataHdr.Channels{channelToRead}(1), 'D', 1))
                        error('Digital chanel doesn''t exist')
                    end
                    
                case 'E' % electrode channel
                    channelName = [channelType 'l_' channelToRead(2:3)];
                    channelToRead = find(strcmp(channelName, dataHdr.Channels));
                    disp('E')
                    
                case 'A' % LEFT TO-DO analog channels
                    
                otherwise % fallback in case something crazy happens
                    
            end
            
            channel_number_to_load(i) = channelToRead;
        end
        
    end

    %% Use fread to import RawData
    
    status = fseek(fid, 0, 'eof'); % command sends the index fid to the end of the file (eof) on the hard drive
    nbr_bytes_last_entry = ftell(fid); % gives the number of bytes in the file
    
    % check if has fixed length, otherwise remember position after
    % header and move by 2 bytes.
    offset_header = position + 2; % header is eg 410, plus 1 block of 2 bytes (2 bytes signal end of header)
    
    % bytes per data point
    bytes_per_data_point = 2;
    % uint16 has 2 bytes per datapoint, hence we divide by 2.
    nbr_samples_per_channel = (nbr_bytes_last_entry - offset_header) / nbr_channels / bytes_per_data_point;
    
    % can not use 'parfor', because we use 'fread' multiple times on the same file.
    for j = 1 : length(channel_number_to_load);
        channelToRead = channel_number_to_load(j);
        % position to start reading
        if ~isempty(time)
            pos_to_start_reading = (channelToRead - 1) * 2 + (time(1) * nbr_channels * 2);
            pos_to_end_reading = (channelToRead - 1) * 2 + (time(2) * nbr_channels * 2);
            %                 readIndex = pos_to_start_reading : nbr_channels * 2 : pos_to_end_reading;
            
            status = fseek(fid, offset_header + pos_to_start_reading, 'bof');
            samplesToRead = time(2) - time(1);
            
            rawData{j} = fread(fid, samplesToRead, 'uint16', (nbr_channels-1)*bytes_per_data_point);
        else
            pos_to_start_reading = (channelToRead - 1) * 2;
            % go to start position
            status = fseek(fid, offset_header + pos_to_start_reading, 'bof');
            
            rawData{j} = fread(fid, nbr_samples_per_channel, 'uint16', (nbr_channels-1)*bytes_per_data_point);
        end
        
    end
    
    
    %% Close the read file
    fclose(fid);
    
    %% Normalization of digital channels
    %     if ~isempty(strmatch('D',channels_to_load)) % see whether there are digital channels among the ones to extract
    %         digitalChannels = strmatch('D',channels_to_load);
    %         for i = 1 : length(digitalChannels) % Go through all the digital channels
    %             rawData{digitalChannels(i)} = DigitalCorr_MCS(rawData{digitalChannels(i)});
    %         end
    %         clear digitalChannels;
    %     end;
    
    %% Scaling analog data according to AD conversion
    % Analog channels aren't electrode channels, but if the 3 additional
    % inputs are set to record in analog mode. LEFT TO-DO!
    A_channels_to_load = strmatch('A', channels_to_load);
    if ~isempty(A_channels_to_load)
        analogChannels = A_channels_to_load;
        for j = 1 : length(analogChannels) % Go through all the analog channels
            rawData{analogChannels(j)} = (rawData{analogChannels(j)}-dataHdr.Import.ADC_Zero)*dataHdr.Import.An_ADStep;
        end
        clear analogChannels;
    end;

    %% Scaling electrode data according to AD conversion
    E_channels_to_load = strmatch('E', channels_to_load);
    if ~isempty(E_channels_to_load)
        electrodeChannels = E_channels_to_load;
        for i = 1 : length(electrodeChannels)
            rawData{electrodeChannels(i)} = (rawData{electrodeChannels(i)}-dataHdr.Import.ADC_Zero)*dataHdr.Import.El_ADStep;
        end
        %         dataHdr.ElecLayout = [2;3;4;5;7;8;9;10;11;12;13;14;15;16;17;18;19;20;21;22;23;24;25;26;27;28;29;30;32;33;34;35];
        %% Generate time axis according to sampling rate and length of electrode raw data
        TimePoints = 1 : size(rawData{electrodeChannels(i)}, 2);
        dataHdr.TimeAxis = (TimePoints/dataHdr.SampleRate)*1000; %Milliseconds
        clear electrodeChannels;

    %     else
    %         %% Create dummy array if no electrode data is available
    %         ElecData = [];
    %
    %         %% Generate time axis according to analog data if no electrode data is recorded
    %         TimePoints = [1:size(AnalogData(1,:),2)];
    %         dataHdr.TimeAxis = (TimePoints/dataHdr.SampleRate)*1000; %Milliseconds
    end

    %% Define variables for output
    
    metadata = dataHdr;
    % for filebrowser
    metadata.max_nbr_samples_in_file = nbr_samples_per_channel;
    metadata.ChannelNames = channels_to_load;
    
    %% Clear all unnecessary variables
    clear dataHdr AnalogData ElecData DigitalData ArtCorrElecData


end

function channellist = get_channel_name_from_string(LabelList, string)

    channellist = strfind(LabelList, string); % find which entities say 'elec' in their label, indicating an analog channel.
    channellist = find(cellfun(@(x) ~isempty(x), channellist));
    
end
%% EOF