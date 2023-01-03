## Ways to specify what to build:

1) Set up the shell environment.
```bash
        source build/envsetup.sh
```
    
2) Select the device to target.
```bash
        setupDevice [<target>] # Selects the device to target
```

3) Build the kernel defconfig.
```bash
        buildDefconfig
```

4) Build the kernel image.
```bash
        buildKernelImage
```
### To Build both defconfig and kernel image.
```bash
        buildKernel
```