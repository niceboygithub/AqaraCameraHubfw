# Aqara Camera Hub G2/G2H (ZNSXJ12LM) related binutils

The repository includes the following feature.

1. busybox-armv7l

   bettery busybox

2. imggrabber

   Use to snapshot of camera

3. h264grabber

   For streaming of camera

4. rRTSPServer (Manually add)
   RTSP server still have some bug on performace and decoding frame, use with your risk.
   Notice: For G2, RTSP server only work at high resolution in firmware 3.5.8, For firmware 3.4.6 and 3.5.7,

###### for Camera G2, open rtsp://[IP]]/ch0_0.h265 (high resolution) or rtsp://[IP]]/ch0_1.h265 (low resolution) with vlc etc.
For low resolution.
```shell
   h264grabber -f -r low &
   rRTSPServer -e -r low &
```
For high resolution.
```shell
   h264grabber -f &
   rRTSPServer -e &
```
###### for Camera G2H, open rtsp://[IP]]/ch0_0.h264 (high resolution) or rtsp://[IP]]/ch0_1.h264 (low resolution) with vlc etc.
For low resolution.
```shell
   h264grabber -f -r low &
   rRTSPServer -r low &
```
For high resolution.
```shell
   h264grabber -f &
   rRTSPServer &
```
   Or copy two binary and a script to /system/bin, then add rtsp_start.sh to /etc/init.d/S90app or use monitor (add configuration to /etc/normal.xml)

5. www.tar.gz
   www folder of httpd, add httpd to /etc/init.d/S90app or use monitor (add configuration to /etc/normal.xml)
   for example
```shell
busybox-armv7l httpd -p 8080 -h /www
```

6. How to enable telnet without open case and no need solder UART (on G2H only from <a href="https://github.com/mcchas/g2h-camera-mods"> @macchas </a>)

   create a file 'hostname' which its content as below and put it in sdcard.
```shell
#!/bin/sh
passwd -d root
echo WITH_TELNET=y >> /etc/.config
```

Then try to use putty to login to see it works or not. If it worked, you can remove hostname

7. How to enable telnet in hard way (need to solder UART)

   See the image to know TX RX of UART and wire out the UART TTL (115200 8N1), login with root/09qjuS@3.
```shell
echo WITH_TELNET=y >> /etc/.config

```
If you want to remove password, you can enter the below command
```shell
passwd -d root

```

<a href="https://www.buymeacoffee.com/niceboygithub" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>