# Aqara Gateway M1S Gen2 (ZHWG22LM) Firmware

Note that flashing firmware is USING AT YOUR OWN RISK.
## Flash M1S Gen2 Custom firmware method

```shell
cd /tmp && wget -O /tmp/curl "http://master.dl.sourceforge.net/project/aqarahub/binutils/curl?viasf=1" && chmod a+x /tmp/curl
/tmp/curl -s -k -L -o /tmp/m1s2_update.sh https://raw.githubusercontent.com/niceboygithub/AqaraCameraHubfw/main/modified/M1S2/m1s2_update.sh
chmod a+x /tmp/m1s2_update.sh && /tmp/m1s2_update.sh
```
