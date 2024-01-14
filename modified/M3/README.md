# Aqara Gateway M3(ZHWG24LM) Firmware

Note that flashing firmware is USING AT YOUR OWN RISK.
## Flash M3 Custom firmware method

```shell
cd /tmp && wget -O /tmp/curl "http://master.dl.sourceforge.net/project/aqarahub/binutils/curl?viasf=1" && chmod a+x /tmp/curl
/tmp/curl -s -k -L -o /tmp/m3_update.sh https://raw.githubusercontent.com/niceboygithub/AqaraCameraHubfw/main/modified/M3/m3_update.sh
chmod a+x /tmp/m3_update.sh && /tmp/m3_update.sh
```
