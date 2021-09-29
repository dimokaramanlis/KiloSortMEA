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
    % Windows 
    proc = System.Diagnostics.Process();
    proc.StartInfo.FileName = converterpath;
    proc.StartInfo.Arguments = argstr; % Default window size is 150 columns and 40 rows
    proc.StartInfo.UseShellExecute = false; % Necessary for redirecting
    proc.StartInfo.RedirectStandardError = true; % Redirect stderr
    proc.Start();
    proc.WaitForExit(); % Wait for the process to end
    exitCode = proc.ExitCode;

    % Display any errors from stderr
    out = proc.StandardError.ReadToEndAsync;
    if (~isempty(out.Result))
        err = erase(string(Trim(out.Result)), char(13));
        err = strsplit(err, newline);
        for e = err
            warning(e);
        end
    end   
elseif isunix
    % Linux
    %  Requires: gnome-terminal and mono-runtime
    stderrfile = tempname;
    shellfile = tempname;
    sfi = fopen(shellfile,'wt');
    fprintf(sfi, 'mono %s %s 2>%s', converterpath, argstr, stderrfile);
    fclose(sfi);
    exitCode = system(...
        sprintf('gnome-terminal --wait --geometry=%ix%i -- bash %s',...
        win_width, win_height, shellfile));
    delete(shellfile);
    
    % Display any erros from stderr
    if isfile(stderrfile)
        err = erase(string(fileread(stderrfile)), char(13));
        err = split(err, newline);
        for e = err'
            warning(e);
        end
        delete(stderrfile);
    end
else
    error('OS not supported');
end
%--------------------------------------------------------------------------
fprintf('Conversion took %3.0f min...\n', toc/60);

% Stop on failure
if exitCode ~= 0
    error('Conversion failed (exit code %d)', exitCode);
end
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

