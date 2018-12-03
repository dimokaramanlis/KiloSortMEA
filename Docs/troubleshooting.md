# Troubleshooting

## GPU out of memory
Problem:

You're getting `CUDA_ERROR_ILLEGAL_ADDRESS` while calculating
the filters or applying them.

Solution:

This is probably caused by running out of GPU memory. Track
the GPU use, see if you're getting close to the maximum. If
so, lowering ops.NT in the config file should help.

## Java error at the end of application of filters
Problem:

You're getting a long error message starting with
`java.lang.ClassCastException: sun.awt.image.BufImgSurfaceData cannot be cast to sun.java2d.xr.XRSurfaceData`

It seems that this is a problem specific to MATLAB on Ubuntu, [here's](https://www.mathworks.com/matlabcentral/answers/373897-external-monitor-throws-java-exception)
the discussion on  MATLAB central.

Solution:

`echo "-Dsun.java2d.xrender=false" | sudo tee /usr/local/MATLAB/R2018a/bin/glnxa64/java.opts`

You may need to adapt the path depending on your MATLAB version.
