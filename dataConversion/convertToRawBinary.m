function [bininfo] = convertToRawBinary(ops)
%CONVERTORAWBINARY 

%--------------------------------------------------------------------------
converterpath = which('ConvertDatMEA.exe');
hexapath      = which('hexaorder.txt');
%--------------------------------------------------------------------------
win_width = 150;
win_height = 40;
argstr = sprintf('-w%i -h%i -nowait %s', win_width, win_height, ops.root);

if any(strcmp(ops.meatype, {'60Hexa', '60hexa'}))
    argstr = [argstr ' -channelorder ' hexapath];
end

fprintf('Saving .mcd data as .dat...\n'); tic;
%--------------------------------------------------------------------------
if ispc
    % Windows part 
    proc = System.Diagnostics.Process();
    proc.StartInfo.FileName = converterpath;
    proc.StartInfo.Arguments = argstr; % Default window size is 150 columns and 40 rows
    proc.Start();
    proc.WaitForExit(); % Wait for the process to end
    proc.ExitCode %Display exit code
elseif isunix
    % Ubuntu
    system(sprintf('gnome-terminal --wait --geometry=%ix%i -- mono %s %s',...
        win_width, win_height, converterpath, argstr)) %Display exit code
else
    error('OS not supported');
end
%--------------------------------------------------------------------------
fprintf('Conversion took %3.0f min...\n', toc/60);
%--------------------------------------------------------------------------
% read bininfo.txt
bininfopath = fullfile(ops.root, 'ks_sorted', 'bininfo.txt');
fid      = fopen(bininfopath);
readinfo = fscanf(fid,'%f');
fclose(fid);

% make bininfo struct
bininfo.NchanTOT    = round(readinfo(1));
bininfo.fs          = round(readinfo(2));
bininfo.convfac     = readinfo(3);
bininfo.stimsamples = round(readinfo(4:end));

nmins = round(sum(bininfo.stimsamples)/bininfo.fs/60);
fprintf('Total length of the recording was %3.0f min...\n', nmins);
%--------------------------------------------------------------------------
end

