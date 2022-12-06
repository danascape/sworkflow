## The current required flags are as follows

### Define the architecture of the kernel source code.
### This is used by `make` to generate the kernel targets.
    TARGET_ARCH

### Define the device codename.
### This is used by the repository script to fetch repositories from the organization.
    TARGET_DEVICE_CODENAME

### Define the device kernel version.
### No specific usage except the menu display
    TARGET_KERNEL_VERSION

### Define the Kernel source directory.
    KERNEL_DIR

### Define the device kernel defconfig
### The defconfig will be located in `${KERNEL_DIR}/arch/${TARGET_ARCH}/configs`
    KERNEL_DEFCONFIG

## The following flags are optional.

### Define if the target uses GCC-4.9 or less
    TARGET_USES_GCC