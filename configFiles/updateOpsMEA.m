

function  ops = updateOpsMEA(metadata, ops)

switch lower(metadata.meatype)
    
    case '60mea20030cellculture'
        
        ops.nt0                 = floor(round(25*ops.fs/1e4)/2)*2+1; %spike template time bins
        ops.nt0min              = floor(round(8*ops.fs/1e4)/2)*2; %spike template time bins
        %ops.minfr_goodchannels  = 0.1;
        %ops.nfilt_factor        = 4;
        ops.minSpks             = 50;
        ops.NT                  = 64*round(512*ops.fs/1e4) + ops.ntbuff;
        ops.momentum            = 1./[20 200];  % start with high momentum and anneal (1./[20 1000])
        ops.nskip               = 1;
        ops.Th               	= [4 8 8];
        ops.freqUpdate          = 100;
        ops.muTh                = 8;
        ops.lam                 = [15 60 60];
        
%         if ~isempty(metadata.chans2del)
%             m = matfile(ops.chanMap); % this is to open the channel map file           
%             ch = m.chanMap; % first get channel ids
%             ch(1:6)= ch(1:6)+11;        % this is to match the numbers to the Multi-channel software
%             ch(7:14)= ch(7:14)+14;      % second row
%             ch(15:22)= ch(15:22)+16;    % third row
%             ch(23:30)= ch(23:30)+18;    % forth row
%             ch(31:38)= ch(31:38)+20;    % fifth row
%             ch(39:46)= ch(39:46)+22;    % sixth row
%             ch(47:54)= ch(47:54)+24;    % seventh row
%             ch(55:60)= ch(55:60)+27;    % last row
%             ch2delidx = find(ismember(ch,metadata.chans2del));  % find the channels to delete
%             if ~isempty(ch2delidx)      % change the file when the numbers are meaningful
%                 m.Properties.Writable = true;  % this is to be able to change the conntected file
%                 disp(['disconnecting noisy channels: ', num2str(ch2delidx)]);
%                 for ii = 1:numel(ch2delidx), m.connected(ch2delidx(ii),1) = false;  end % for loop to avoid some equal range index bullshit
%                 m.Properties.Writable = false; % change the permission of the file back!
%             end
%         end
    case '60mea20030hippocampus'
        ops.nt0                 = floor(round(40*ops.fs/1e4)/2)*2+1; %spike template time bins
        ops.nt0min              = floor(round(12*ops.fs/1e4)/2)*2; %spike template time bins
        ops.minfr_goodchannels  = 0.05;
        %ops.nfilt_factor        = 4;
        ops.minSpks             = 10;
        ops.NT                  = 64*round(512*ops.fs/1e4) + ops.ntbuff;
        ops.momentum            = 1./[20 200];  % start with high momentum and anneal (1./[20 1000])
        ops.nskip               = 1;
        ops.Th               	= [4 10 10];
        ops.freqUpdate          = 100;
        ops.muTh                = 8;
        ops.lam                 = [15 60 60];
        
        
    otherwise
        error(['There aint no option ',metadata.exptypes,' is not defined, check your shit first!']);
end

end