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

This is likely caused by the large Java objects created by MATLAB.
Increase the Java object memory allocation under
General > Java Heap Memory in MATLAB preferences.
