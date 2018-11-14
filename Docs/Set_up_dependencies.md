# Installing dependencies of KiloSort

We need to copy some other repositories:

- [npy-matlab](https://github.com/kwikteam/npy-matlab) to allow KiloSort to write npy files
- [Phy](https://github.com/kwikteam/phy) to visualize and manipulate the output
of the spike sorting
- Neuroshare to be able to read from .MCD files

It's a good idea to place all of these repositories together in a main folder as
well as KiloSort itself. e.g. ~/repos/

## npy-matlab

```bash
cd ~/repos
git clone https://github.com/kwikteam/npy-matlab
```

To tell MATLAB to use this folder:

Add the following to ~/Documents/MATLAB/startup.m file

`addpath(genpath("~/repos/npy-matlab"))`


## Phy

Following the guidelines from [github page of Phy](https://github.com/kwikteam/phy)

Make sure you have conda installed.

- Download the [conda environment file](https://raw.githubusercontent.com/kwikteam/phy/master/installer/environment.yml)
```bash
conda env create -f ~/Downloads/environment.yml
source activate phy
```

   - If you're getting import error with pip.\_internal, you need to manually
   specify its version. Use this as your .yml file instead.

        ```yml
        name: phy
        dependencies:
          - python=3.5
          - numpy
          - matplotlib
          - scipy
          - h5py
          - cython
          - pyqt=4
          - pip=9.0.3

        ```
   - Install the required pip packages manually

   `pip install klusta klustakwik2 vispy requests traitlets six joblib click
   tqdm`

## Neuroshare

Download the neuroshare library for matlab [here](https://github.com/downloads/G-Node/nsmatlab/neuroshare-matlab-Linux-x86_64.tar.gz).

Export the contents into `~/repos/neuroshare-matlab` and add this to your
MATLAB path `addpath(genpath("~/repos/neuroshare-matlab"))`


Download the library files MultiChannel Systms
for Linux [here](http://download.multichannelsystems.com/download_data/software/neuroshare/nsMCDLibrary_Linux64_3.7b.tar.gz).

Place the two files under `nsMCDLibrary` into `/usr/lib/neuroshare/`

This will enable access to the library from neuroshare API for MATLAB
as well as the [Pyhton version](https://github.com/G-Node/python-neuroshare), in
case you decide to use it.
