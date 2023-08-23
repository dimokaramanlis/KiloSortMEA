function samplelist = concatenateAndCleanBinaries(dpfile, dptarget)

%dpfile = {'', ''}; % fill this with the paths you want 
%dptarget = 'finalbin.bin';


fidtarget = fopen(dptarget, 'W');
NchanTOT = 385;
batchsamples = 0.5*30000;
ichuse = 1:384;
Nuse = numel(ichuse);
samplelist = zeros(numel(dpfile), 1); % samplelist is important to tell us how to split files later
scaleproc = 200;
tic;
for ifile = 1:numel(dpfile)
    fprintf('Going through file %d...\n', ifile);
    s = dir(dpfile{ifile});         

    bytes =  s.bytes; % size in bytes of raw binary
    nTimepoints = floor(bytes/NchanTOT/2); % number of total timepoints
    Nbatch      = ceil(nTimepoints/batchsamples);
    
    fid = fopen(dpfile{ifile},'r');
    for ibatch = 1:Nbatch %608
        sampsread = min(batchsamples, nTimepoints - (ibatch-1)*batchsamples);
        fseek(fid, (ibatch-1)*batchsamples*NchanTOT, 'bof'); % fseek to batch start in raw file
        dat = fread(fid, [NchanTOT sampsread], '*int16');

        dataRAW = gpuArray(dat(ichuse,:));
        dataRAW = dataRAW';
        dataRAW = single(dataRAW)/scaleproc;
        
        %dataRAW = dataRAW-median(dataRAW,2);

        [aa,bb,cc] = svd(dataRAW,'econ');
        
        Ncomps = 5;
        toremove = aa(:,1:Ncomps)*bb(1:Ncomps,1:Ncomps)*cc(:,1:Ncomps)';
        
        dataDEN = dataRAW - toremove;
        datcpu  = gather(int16(dataDEN*scaleproc)); % convert to int16, and gather on the CPU side


        fwrite(fidtarget, datcpu', 'int16');
        if mod(ibatch,50) == 1
            fprintf('Batch %d/%d. Time %ds \n', ibatch, Nbatch, round(toc));
        end
    end
    fclose(fid);
    samplelist(ifile) = nTimepoints;
end
fclose(fidtarget);

[targetfolder, ~] = fileparts(dptarget);
save(fullfile(targetfolder, 'samplelist.mat'), 'samplelist','dpfile');

end


