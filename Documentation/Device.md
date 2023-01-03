* The device tree is a device configuration script that is picked up by the build system as per the specified target.
* The device tree consists of device specific which defines the target product properties.

### Ways to generate the device-specific tree structure
Refer to [Device Flags](Flags.md) for more information.

#### The tree is generated to define device specific flags.
#### The generated device tree is required to be stored at
    device/${OEM_NAME}/${TARGET_DEVICE_CODENAME}

##### The `OEM_NAME` is the manufacturer of the target device.
##### The `TARGET_DEVICE_CODENAME` is the codename of the target device.
#### Reference device tree can be found at https://github.com/StormBreaker-Devices/kernel_device_asus_X00P.