


exepath = 'C:\Users\admin_lokal\Documents\GitHub\KiloSortMEA\dataConversion\sz_conversion';

dp = 'H:\20210813_DK_252MEA3008_le_sr_sp_unknown';
stimfiles = dir([dp,filesep,'*.mcd']);

namelist = {stimfiles.name}';
filenum = cellfun(@(x)sscanf(x,'%d_yy.txt'),namelist);
[~,Sidx] = sort(filenum);

stimfiles = stimfiles(Sidx);
mcdfilenames = cellfun(@(x) fullfile(dp, x), {stimfiles.name}', 'un', 0);

sinput = strjoin(mcdfilenames(1:5));
% this works

bfilepath = 'C:\Users\admin_lokal\Desktop\example.bat';
[status,cmdout] = system([bfilepath ' &'])

% test 
[status,cmdout] = system(['cd ' exepath]);
tic;
[status,cmdout] = system(['ConvertDatMEA -nowait ' sinput], '-echo')
aa = 5;
toc;

!cmd
! bfilepath &

!cmd &
! cd C:\Users\admin_lokal\Documents\GitHub\KiloSortMEA\dataConversion\sz_conversion &

! cmd

!['ConvertDatMEA -nowait ' sinput] &
[status,cmdout] = system(['ConvertDatMEA -nowait ' sinput],'-echo')


%% ==================
tic;
proc = System.Diagnostics.Process();
proc.StartInfo.FileName = fullfile(exepath, 'ConvertDatMEA.exe');
proc.StartInfo.Arguments =  ['-nowait -w150 -h40 ' dp]; % Default window size is 150 columns and 40 rows
proc.Start();
proc.WaitForExit(); % Wait for the process to end
proc.ExitCode %Display exit code
toc;


