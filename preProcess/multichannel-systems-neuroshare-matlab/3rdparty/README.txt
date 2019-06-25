HOW TO GET 3rdparty code up and running:

1) compile code as described in 'MatLab/Matlab-Import-Filter/Mex_Sources/how_to_compile_linux.txt'

2) copy 'MatLab/Matlab-Import-Filter/Mex_Sources/mexprog.mexa64' to 'MatLab/Matlab-Import-Filter/Matlab_Interface/'

3) copy 'nsMCDLibrary/*' to 'MatLab/Matlab-Import-Filter/Matlab_Interface/'

4) open matlab and go into folder 'MatLab/Matlab-Import-Filter/Matlab_Interface/'

5) run 'addpath(pwd)'

6) try to run 'Example()'
   - DLL Name: nsMCDLibrary.so
   - Data file: /path/to/3rdparty/ExampleMCD/NeuroshareExample.mcd

 -> this will fail.

7) go to 'MatLab' and open 'Neuroshare.m'
  
8) run the code and change the paths accordingly, e.g.:
   [nsresult] = ns_SetLibrary('Matlab-Import-Filter/Matlab_Interface/nsMCDLibrary.so')
   [nsresult, hfile] = ns_OpenFile([examplepath '/../ExampleMCD/NeuroshareExample.mcd'])

9) everything should work, exept calling 'ns_GetSegmentData', which results in a 'out of memory'

 ??? Error using ==> mexprog
Out of memory. Type HELP MEMORY for your options.

Error in ==> ns_GetSegmentData at 48
[ns_RESULT, TimeStamp, Data, SampleCount, UnitID] = mexprog(11, hFile, EntityID - 1,
Index - 1);


