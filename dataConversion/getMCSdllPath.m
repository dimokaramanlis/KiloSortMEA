function [dllpath,libtoload] = getMCSdllPath()
%GETMCSDLLPATH Summary of this function goes here

switch computer()
    case 'PCWIN'; libtoload = 'nsMCDLibraryWin32.dll';
    case 'GLNX86'; libtoload = 'nsMCDLibraryLinux32.so';
    case 'PCWIN64'; libtoload = 'nsMCDLibraryWin64.dll';
    case 'GLNXA64'; libtoload = 'nsMCDLibraryLinux64.so';
    case 'MACI64'; libtoload = 'nsMCDLibraryMacIntel.dylib';
    otherwise, disp('Your architecture is not supported'); return;
end

dlllocation = which(libtoload);
dllpath = fileparts(dlllocation);

end