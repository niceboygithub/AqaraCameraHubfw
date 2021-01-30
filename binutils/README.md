# Aqara Camera Hub G2/G2H (ZNSXJ12LM) related binutils

The repository includes the following feature.

1. busybox-armv7l

   bettery busybox
    

2. imggrabber

   Use to snapshot of camera

3. h264grabber

   For streaming of camera

4. rRTSPServer

   RTSP server. 
   Notice: For G2, RTSP server only work low resolution and firmware version 3.4.6 and 3.5.7.
   for Camera G2
```shell
   h264grabber -f -r LOW &
   RRTSP_RES=1 rRTSPServer &
```
   for Camera G2H
```shell
   h264grabber -f &
   rRTSPServer
```
   copy two binary to /system/bin, then add to /etc/init.d/S90app or use monitor (add configuration to /etc/normal.xml)

5. www.tar.gz
   www folder of httpd, add to /etc/init.d/S90app or use monitor (add configuration to /etc/normal.xml)
   for example
```shell
busybox-alt httpd -p 8080 -h /www
```

6. How to enable
   Wire out the UART TTL, login with root/09qjuS@3.
```shell
echo WITH_TELNET=y >> /etc/.config

```

<a href="https://www.buymeacoffee.com/niceboygithub" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>