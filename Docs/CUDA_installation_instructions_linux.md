Installing CUDA on Ubuntu 16.04
------

Pick which version you need based on your [MATLAB version](https://www.mathworks.com/help/distcomp/gpu-support-by-release.html),
it probably will not work with another version of CUDA toolkit.

This guide is based on MATLAB2018a and CUDA v9.0.

The steps are based on this guide:
https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html

kernel headers and development packages are required for CUDA to work
After each update to the kernel, headers and development packages need to be
installed as well(?).

`sudo apt-get install linux-headers-$(uname -r)`

Use the deb installer for installing CUDA, not the runfile because it
might mess up dependecies of other programs in the future.

Download the relevant version of CUDA from [here.](https://developer.nvidia.com/cuda-toolkit-archive)
For this guide, we are using 9.0 with the following options:

| | |
|---------------|------|
|OS		| Linux|
|Architecture 	|x86_64|
|Distribution	|Ubuntu|
|Version	|16.04 (There is no 18.04 yet)|
|Installer Type |deb(local)|

Run the following commands as described in the nvidia guide.

`sudo dpkg -i cuda-repo-ubuntu1604-9-0-local_9.0.176-1_amd64.deb`

`sudo apt-key add /var/cuda-repo-9-0-local/7fa2af80.pub`

`sudo apt update`

`sudo apt install cuda`

Add the following to ~/.bashrc

`export PATH="/usr/local/cuda-9.0/bin:$PATH"`


To test if your installation succeeded:

`source .bashrc`

`nvcc -V`

You should see version information on CUDA tools.

To actually test that CUDA is working:

`cd /usr/local/cuda-9.0/samples`

`sudo make` (might fail at some point, but it does not matter, these are just examples)

`cd /usr/local/cuda-9.0/samples/bin/x86_64/linux/release`
`./deviceQuery`

**Note**:
To have the .bashrc work with MATLAB, matlab should be run from
the commmand line.


Now you should be able to run mexGPUall.m
