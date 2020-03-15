function savePrincipalComponentsKS1(rez, savepath_pc)
%SAVEPRINCIPALCOMPONENTS Summary of this function goes here
%   Detailed explanation goes here

%==========================================================================
nNeighPC     = rez.ops.nNeighPC;
Nrank        = 3;
[mpath, ~]   = fileparts(rez.ops.fproc);

Nspikes      = size(rez.st3, 1);
Nunits       = rez.ops.Nfilt; 
spkinds      = accumarray(rez.st3(:,2), 1:size(rez.st3,1), [Nunits, 1],@(x) {x});
spkinds      = cellfun(@(x) sort(x,'ascend'), spkinds, 'un', 0);
nspks        = cellfun(@numel, spkinds);
%==========================================================================
shape_pc    = [Nspikes Nrank nNeighPC];
header_pc   = constructNPYheader('single', shape_pc);
%==========================================================================
% save PC file

fid_pc = fopen(savepath_pc, 'W');
fwrite(fid_pc, header_pc, 'uint8'); % write header first
Ndims = Nrank * nNeighPC;
Nbatch = 5; batchsize = ceil(Ndims/Nbatch);

for ibatch = 1:Nbatch

    dimswrite = min(batchsize, Ndims - (ibatch-1)*batchsize);
	istart    = (ibatch - 1)*batchsize + 1;
	iend      = istart + dimswrite - 1;
	
	pcwrite = zeros(Nspikes, dimswrite, 'single');
	
	for iunit = 1:Nunits
	    pcpath = fullfile(mpath, sprintf(rez.cProjPCpath, iunit));
		if ~exist(pcpath, 'file'), continue; end 
	
		fid_pc_unit = fopen(pcpath, 'r');
	    pcmat       = fread(fid_pc_unit, [nspks(iunit) Ndims],'*single');
		fclose(fid_pc_unit);
		
        if isempty(pcmat), continue; end % empty appears when spikes are deleted from set_cutoff
        
		pcwrite(spkinds{iunit}, :) = pcmat(:, istart:iend);
	end
	
    fwrite(fid_pc, pcwrite, 'single');	
	
end

fclose(fid_pc); clear pcwrite;
%==========================================================================
% delete single unit files
for iunit = 1:Nunits
	pcpath   = fullfile(mpath, sprintf(rez.cProjPCpath, iunit));
    if exist(pcpath,   'file'), delete(pcpath);   end 
end
%==========================================================================

end

