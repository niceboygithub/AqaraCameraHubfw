# Aqara Gateway M2 2022 (PoE, ZHWG19LM) Firmware

Note that flashing firmware is USING AT YOUR OWN RISK.
## Flash M2 2022 (PoE) Custom firmware method

```shell
cd /tmp && wget -O /tmp/curl "http://master.dl.sourceforge.net/project/aqarahub/binutils/curl?viasf=1" && chmod a+x /tmp/curl
/tmp/curl -s -k -L -o /tmp/m2poe_update.sh https://raw.githubusercontent.com/niceboygithub/AqaraCameraHubfw/main/modified/M2PoE/m2poe_update.sh
chmod a+x /tmp/m2poe_update.sh && /tmp/m2poe_update.sh
```
