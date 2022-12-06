Kernel build system usage:

Ways to specify what to build:
    # Set up the shell environment.
    source build/envsetup.sh

    # Select the device to target. In the case of no argument,
    # the script will fail.
    setupDevice [<target>] # Selects the device to target

    # Build the kernel defconfig.
    buildDefconfig

    # Build the kernel image.
    buildKernelImage

    # Build both defconfig and kernel image.
    # This will select both the defconfig and the kernel image target.
    buildKernel

Ways to generate the device-specific tree structure
<br>
    # The tree is generated to define device specific flags.
    <br>
    # The generated device tree is required to be stored at
    <br>
      `device/${OEM_NAME}/${TARGET_DEVICE_CODENAME}`
    <br>
    # The `OEM_NAME` is the manufacturer of the target device.
    <br>
    # The `TARGET_DEVICE_CODENAME` is the codename of the target device.
    <br>
    # Reference device tree can be found at https://github.com/StormBreaker-Devices/kernel_device_asus_X00P.

    # The current required flags are as follows

    # Define the architecture of the kernel source code.
    # This is used by `make` to generate the kernel targets.
    TARGET_ARCH

    # Define the device codename.
    # This is used by the repository script to fetch repositories
      from the organization.
    TARGET_DEVICE_CODENAME

    # Define the device kernel version.
    # No specific usage except the menu display
    TARGET_KERNEL_VERSION

    # Define the Kernel source directory.
    KERNEL_DIR

    # Define the device kernel defconfig
    # The defconfig will be located in `${KERNEL_DIR}/arch/${TARGET_ARCH}/configs`
    KERNEL_DEFCONFIG

    # The following flags are optional.

    # Define if the target uses GCC-4.9 or less
    TARGET_USES_GCC

Building Kernel
<br>
  You can execute a sample build by :-
  `source build/envsetup.sh`
  <br>
  `selectDevice X00P`
  <br>
  `buildDefconfig`
  <br>
  `buildKernelImage`