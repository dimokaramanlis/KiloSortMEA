function rez = combineAndSortFeaturesKS1(rez, st3)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
% 
% %==========================================================================
fWpcpath = rez.fWpcpath;
[mpath, ~]     = fileparts(fWpcpath);
Nunits = rez.ops.Nfilt;

nNeighPC = rez.ops.nNeighPC;
Nrank   = 3;

spkinds = accumarray(st3(:,2), 1:size(st3,1), [Nunits, 1], @(x) {x});
nspks   = cellfun(@numel, spkinds);
nspktot = sum(nspks);
Nbatch  = 5;

%--------------------------------------------------------------------------
fprintf('Writing principal components to hard drive...\n');

batchspikes = ceil(nspktot/Nbatch);

for ibatch = 1: Nbatch
    
    spksread = min(batchspikes, nspktot - (ibatch-1)*batchspikes);
    istart = batchspikes * (ibatch-1) + 1;
    iend   = istart + spksread - 1;
    cspikes = st3(istart:iend, 2);
    
    fid_pc = fopen(fWpcpath, 'r');
    offset_pc = 4 * batchspikes * (ibatch-1) * nNeighPC * Nrank;
    fseek(fid_pc, offset_pc, 'bof');
    dat_pc = fread(fid_pc, [nNeighPC * Nrank spksread], '*single');
    fclose(fid_pc);
    
    
    for iunit = 1:Nunits
        unitpath_pc   = fullfile(mpath,   sprintf('pcs_%04d.dat', iunit));

        % change parts
        unitpcs   = dat_pc  (:, cspikes == iunit);

        % write pcs
        fidunit_pc = fopen(unitpath_pc, 'A');
        fwrite(fidunit_pc, unitpcs, 'single');
        fclose(fidunit_pc);
        
    end

end
delete(fWpcpath); toc;
%--------------------------------------------------------------------------
% sort and permute for each cell
fprintf('Sorting components for each cell...\n');
for iunit = 1:Nunits
    
    currinds   = sort(spkinds{iunit}, 'ascend');
    if isempty(currinds), continue; end
    [~, csort] = sort(st3(currinds,1), 'ascend');
    
    %----------------------------------------------------------------------
    
    unitpath_pc   = fullfile(mpath, sprintf('pcs_%04d.dat', iunit));

    % read
    fidunit_pc = fopen(unitpath_pc, 'r');
    unitpcs = fread(fidunit_pc, [Nrank*nNeighPC nspks(iunit)],'*single');
    fclose(fidunit_pc);
    
    unitpcs = unitpcs';
    unitpcs = unitpcs(csort, :);
    unitpcs = reshape(unitpcs, [nspks(iunit) nNeighPC, Nrank]);
    %unitpcs = reshape(unitpcs, Nrank, nNeighPC, []);
    %assert( size(unitpcs, 3) == nspks(iunit));

    
    [~, isortNeigh]         = sort(rez.iNeighPC(:, iunit), 'ascend');
    OneToNpc                = 1:nNeighPC;
    OneToNpc(isortNeigh)    = OneToNpc;
    
    unitpcs   = unitpcs(:, OneToNpc, :);
    
     % change parts
    unitpcs    = permute(unitpcs, [1 3 2]);
    
    % write again
    fidunit_pc = fopen(unitpath_pc, 'W');
    fwrite(fidunit_pc, unitpcs, 'single');
    fclose(fidunit_pc);   
    %----------------------------------------------------------------------
end

toc;

rez.cProjPC = []; rez.cProjPCpath = 'pcs_%04d.dat';
%==========================================================================
end

