# Aqara Smart Wall Hub V1 (AHWG11LM) Firmware

Note that flashing firmware is USING AT YOUR OWN RISK.
## Flash V1 Custom firmware method

```shell
cd /tmp && wget -O /tmp/curl "http://master.dl.sourceforge.net/project/aqarahub/binutils/curl?viasf=1" && chmod a+x /tmp/curl
/tmp/curl -s -k -L -o /tmp/v1_update.sh https://raw.githubusercontent.com/niceboygithub/AqaraCameraHubfw/main/modified/V1/v1_update.sh
chmod a+x /tmp/v1_update.sh && /tmp/v1_update.sh
```
