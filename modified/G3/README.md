# Bricked WARNING
Because the rootfs of Camera G3 is signed, please use this flash method with think twice.

# Aqara Camera G3 (ZNSXJ13LM) Firmware

Note that flashing firmware is USING AT YOUR OWN RISK.
## Flash G3 Custom firmware method

```shell
cd /tmp && wget -O /tmp/curl "http://master.dl.sourceforge.net/project/aqarahub/binutils/curl?viasf=1" && chmod a+x /tmp/curl
/tmp/curl -s -k -L -o /tmp/g3_update.sh https://raw.githubusercontent.com/niceboygithub/AqaraCameraHubfw/main/modified/G3/g3_update.sh
chmod a+x /tmp/g3_update.sh && /tmp/g3_update.sh
```

If boot up failed after flashed modified firmware, you can use the [sd card flash method](https://github.com/niceboygithub/AqaraGateway#for-g3-g2h-pro) to downgrade to 3.3.4.
Then enable telnet with aQRootG3 again and flash the modified firmware.
