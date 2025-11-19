# Aqara Gateway M200(AG047GLB02) Firmware

Note that flashing firmware is USING AT YOUR OWN RISK.
## Flash M200 Custom firmware method

```shell
cd /tmp && wget -O /tmp/curl "http://master.dl.sourceforge.net/project/aqarahub/binutils/curl?viasf=1" && chmod a+x /tmp/curl
/tmp/curl -s -k -L -o /tmp/m200_update.sh https://raw.githubusercontent.com/niceboygithub/AqaraCameraHubfw/main/modified/M200/m200_update.sh
chmod a+x /tmp/m200_update.sh && /tmp/m200_update.sh
```
