Kernel build system usage:

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