See 'how_to_compile_linux.txt' for linux instructions.

To build the mexprog library file for your plattform:
- Change into the directory where the sources are
- the just type:
mex main.c mexversion.c ns.c -output mexprog
  in Matlab

To change the compiler used by mex type
mex -setup

Tested for VS2005, VS2008, build in compiler on Win32, build in compiler on Maci
