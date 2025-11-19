# Enable Telnet of Aqara Gateway M200

The easy way to enable telnet of Aqara Gateway M200 is that flash customized firmware.

What is the modification in the customzied firmware?
1. Remove th login password of telnet
2. Run telnetd as default.
3. Run mosquitto as public

The method:
1. Remove the power of the gateway.
2. Copy the [kernel.bin and rootfs.bin](https://github.com/niceboygithub/AqaraCameraHubfw/tree/main/modified/M200) to USB disk in FAT32 format.
3. Plug-in the USB disk to the gateway.
4. Press the front button of the gateway without release
5. Plug-in USB type-C or the PoE lan cable to the gateway
6. When the LED turn to the purple, release the button.
7. After the flash is completed, the gateway will reboot to normal.
